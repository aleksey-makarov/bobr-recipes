#!/usr/bin/env python3
"""bobr-mcp-local -- a tiny local MCP server that runs bobr builds for the agent.

Why it exists: the Claude Code agent runs under NoNewPrivs=1, which neutralises
the setuid `newuidmap` that bobr's user-namespace sandbox needs, so the agent
cannot run real package builds itself -- and neither could any process it spawns
(NoNewPrivs is inherited). This server is launched by the user in a normal shell
(NoNewPrivs=0), so it CAN build. The agent reaches it over localhost HTTP; since
the server is not a child of the agent, the restriction never applies to it.

It exposes one capability: run `bin/bobr-build.sh <profile> --target <target>`
and stream the result back. The single `bobr_build` tool keeps the request open
and streams notable build lines as progress while the build runs (the open call
is the push channel, and a heartbeat keeps it alive through the long silent
stretches of a compile, so even multi-hour builds never time out), then returns a
structured outcome: the exit code, the `done: X built · Y failed` line, the
source hash reported by a placeholder-hash mismatch, any build error, and the
path of the failing sandbox log (which the agent reads itself from the store).

The build profile names the store, so it decides where everything is built; it
is passed explicitly rather than left to the working directory. The bobr
binaries come from the development bin directory, which is put at the front of
the child's PATH -- so whichever `bobr` was last installed by
the engine's tools/build-dev.sh is the one that builds, whatever PATH the shell
that started this server happened to have.

Run it (in a normal, non-no_new_privs shell on the machine that owns the store):

    pip install mcp                                        # one-time
    python3 bobr-recipes/tools/bobr-mcp-local.py       # binds 127.0.0.1:8765

Point Claude Code at it (streamable-http endpoint is /mcp):

    claude mcp add --transport http bobr-local http://127.0.0.1:8765/mcp

Scope: it only ever runs `bobr-build.sh <profile> [--dry-run] [--jobs N]
--target <target>` (target validated against [A-Za-z0-9_]+) in the store the
profile names. It never deletes or cleans anything, and it serialises builds so
two never run at once.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import shutil
import subprocess
import time
from pathlib import Path

from mcp.server.fastmcp import Context, FastMCP

# tools/bobr-mcp-local.py -> up through tools/ to the recipes root.
RECIPES_DIR = Path(__file__).resolve().parent.parent
WORKSPACE_DIR = RECIPES_DIR.parent
BUILD_SH = RECIPES_DIR / "bin" / "bobr-build.sh"
DEFAULT_PROFILE = WORKSPACE_DIR / "bobr.ncl"
DEFAULT_BIN_DIR = Path(
    os.environ.get("BOBR_DEV_BIN") or WORKSPACE_DIR / "bobr-bin" / "bin"
)

TARGET_RE = re.compile(r"^[A-Za-z0-9_]+$")
HASH_RE = re.compile(r"unexpected object hash:.*got ([0-9a-f]{64})")
OBJECT_HASH_RE = re.compile(r"^[0-9a-f]{64}$")
# Matches both renderings of the run totals: the live block's "done: ..."
# and the plain line's "...; N built · N cache-hit · N failed".
SUMMARY_RE = re.compile(r"\d+ built.*?\d+ failed")
ERROR_RE = re.compile(r"error\[build-failed\]:.*")
LOGPATH_RE = re.compile(r"stdout=(\S+\.log)")
NINJA_RE = re.compile(r"\[(\d+)/(\d+)\]")
# How often to speak up when the build is otherwise silent. Comfortably under
# the MCP client's idle timeout, which aborts a call that says nothing.
HEARTBEAT_SECONDS = 30.0
# Lines worth forwarding as progress; the rest is buffered but not streamed, so
# compile spam does not drown the useful markers.
INTERESTING_RE = re.compile(
    r"(==>|done:|error|ERROR|FAILED|warning:|unexpected object hash|"
    r"Sandbox |Did not find|not found|ERROR:)"
)

mcp = FastMCP("bobr-local")
_build_lock = asyncio.Lock()

# Set by main() before the server starts serving.
_profile_path: Path = DEFAULT_PROFILE
_bin_dir: Path = DEFAULT_BIN_DIR


def _child_env() -> dict[str, str]:
    """Environment for bobr-build.sh: the development bin directory first.

    Prepending rather than resolving the binaries here is deliberate -- the
    installer replaces them in place, so a long-lived server keeps picking up
    whatever was installed last without being restarted.
    """
    env = dict(os.environ)
    env["PATH"] = f"{_bin_dir}{os.pathsep}{env.get('PATH', '')}"
    return env


def _resolve_bobr() -> str | None:
    return shutil.which("bobr", path=_child_env()["PATH"])


async def _stream_stderr(
    stream: asyncio.StreamReader, ctx: Context, tail: list[str], seen: dict
) -> None:
    """Buffers the build's diagnostic stream and forwards notable lines."""
    async for raw in stream:
        line = raw.decode("utf-8", "replace").rstrip("\n")
        tail.append(line)
        seen["last"] = line
        # Keep only the recent lines: the summary/hash/error land at the end.
        if len(tail) > 800:
            del tail[:400]
        ninja = NINJA_RE.search(line)
        if ninja:
            done, total = int(ninja.group(1)), int(ninja.group(2))
            if total and (done == total or done % 25 == 0):
                await ctx.report_progress(done, total)
                seen["sent"] = time.monotonic()
        elif INTERESTING_RE.search(line):
            await ctx.info(line)
            seen["sent"] = time.monotonic()


async def _heartbeat(ctx: Context, seen: dict) -> None:
    """Keeps the open call alive while the build is quiet.

    Only notable lines are forwarded, and a single long compile produces none
    of them for many minutes; the client then sees an idle channel and aborts
    the call, even though the build is healthy and still running. So say
    something on a timer -- what the build last printed, and for how long it has
    been going -- whenever nothing notable has gone out recently.
    """
    started = time.monotonic()
    while True:
        await asyncio.sleep(HEARTBEAT_SECONDS)
        if time.monotonic() - seen["sent"] < HEARTBEAT_SECONDS:
            continue
        minutes = (time.monotonic() - started) / 60
        await ctx.info(
            f"[{minutes:.0f}m] building; last output: {seen['last'] or '(none yet)'}"
        )
        seen["sent"] = time.monotonic()


async def _read_stdout(stream: asyncio.StreamReader) -> str:
    return (await stream.read()).decode("utf-8", "replace")


@mcp.tool()
async def bobr_build(
    target: str, ctx: Context, dry_run: bool = False, jobs: int | None = None
) -> dict:
    """Run `bobr-build.sh --target <target>` against the configured profile.

    Streams notable build lines as progress while it runs (long builds never time
    out), then returns a structured result. On a placeholder-hash first build,
    `source_hash` carries the real hash to paste into the recipe.

    Args:
        target: bobr recipe attribute, e.g. "gnome_settings_daemon" or
            "test_gnome_rootfs". Must match [A-Za-z0-9_]+.
        dry_run: pass --dry-run (validate and lower the request only, no build).
        jobs: cap concurrent builds; the default is one per core.
    """
    if not TARGET_RE.match(target):
        raise ValueError(f"invalid target {target!r}: expected [A-Za-z0-9_]+")
    if jobs is not None and jobs < 1:
        raise ValueError(f"invalid jobs {jobs!r}: expected a positive integer")
    if not BUILD_SH.is_file():
        raise FileNotFoundError(f"bobr-build.sh not found at {BUILD_SH}")
    if not _profile_path.is_file():
        raise FileNotFoundError(
            f"no build profile at {_profile_path}; copy "
            f"{RECIPES_DIR / 'bobr.ncl.example'} there, or start this server "
            f"with --profile"
        )
    if _resolve_bobr() is None:
        raise FileNotFoundError(
            f"no 'bobr' on PATH, and none in {_bin_dir}; build one with "
            f"the engine's tools/build-dev.sh"
        )

    # The profile is passed explicitly: relying on the working directory would
    # make the result depend on where this server happens to have been started.
    argv = [str(BUILD_SH), str(_profile_path)]
    if dry_run:
        argv.append("--dry-run")
    if jobs is not None:
        argv += ["--jobs", str(jobs)]
    argv += ["--target", target]

    async with _build_lock:
        await ctx.info(f"$ {' '.join(argv)}")
        proc = await asyncio.create_subprocess_exec(
            *argv,
            cwd=str(RECIPES_DIR),
            env=_child_env(),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        assert proc.stdout is not None and proc.stderr is not None
        tail: list[str] = []
        # The two streams are kept apart: stdout carries the payload (the root
        # object hash, or the lowered request under --dry-run), stderr carries
        # the diagnostics worth streaming and parsing. Merging them, as this
        # once did, buried the diagnostics under a dump of request JSON.
        seen = {"last": "", "sent": time.monotonic()}
        beat = asyncio.create_task(_heartbeat(ctx, seen))
        try:
            stdout_text, _ = await asyncio.gather(
                _read_stdout(proc.stdout),
                _stream_stderr(proc.stderr, ctx, tail, seen),
            )
            exit_code = await proc.wait()
        finally:
            beat.cancel()

    text = "\n".join(tail)
    hash_m = HASH_RE.search(text)
    summary_m = SUMMARY_RE.search(text)
    error_m = ERROR_RE.search(text)
    logpath_m = LOGPATH_RE.search(text)

    result = {
        "target": target,
        "profile": str(_profile_path),
        "dry_run": dry_run,
        "jobs": jobs,
        "exit_code": exit_code,
        "ok": exit_code == 0,
        "summary": summary_m.group(0) if summary_m else None,
        # Real fsobj-hash from a placeholder-hash build; paste it into the recipe.
        "source_hash": hash_m.group(1) if hash_m else None,
        "error": error_m.group(0) if error_m else None,
        # Path of the failing sandbox step log; the agent reads it from the store.
        "failed_log": logpath_m.group(1) if logpath_m else None,
        "tail": tail[-40:],
    }

    if dry_run:
        # Report the shape of the lowered request rather than its megabytes; the
        # agent can lower it again itself if it wants the whole thing.
        try:
            request = json.loads(stdout_text)
            result["nodes"] = len(request.get("nodes", {}))
            result["store"] = request.get("store")
        except json.JSONDecodeError:
            result["nodes"] = None
    else:
        last = stdout_text.strip().splitlines()
        if last and OBJECT_HASH_RE.match(last[-1].strip()):
            result["object_hash"] = last[-1].strip()

    return result


def _report_setup() -> None:
    """Prints what this server will actually build with.

    A missing profile or missing binaries are reported but not fatal: the usual
    fix is to create them in the workspace this server is already watching, and
    it will pick them up on the next build.
    """
    print(f"bobr-mcp-local: recipes:  {RECIPES_DIR}", flush=True)

    if _profile_path.is_file():
        print(f"bobr-mcp-local: profile:  {_profile_path}", flush=True)
    else:
        print(
            f"bobr-mcp-local: WARNING: no build profile at {_profile_path}",
            flush=True,
        )

    bobr_path = _resolve_bobr()
    if bobr_path is None:
        print(
            f"bobr-mcp-local: WARNING: no 'bobr' on PATH, and none in {_bin_dir}",
            flush=True,
        )
        return
    try:
        version = subprocess.run(
            [bobr_path, "--version"],
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        ).stdout.strip()
    except (OSError, subprocess.SubprocessError) as error:
        version = f"(could not run --version: {error})"
    print(f"bobr-mcp-local: bobr:     {bobr_path} -- {version}", flush=True)


def main() -> None:
    global _profile_path, _bin_dir

    parser = argparse.ArgumentParser(description="local bobr build MCP server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument(
        "--profile",
        type=Path,
        default=DEFAULT_PROFILE,
        help=f"build profile naming the store (default: {DEFAULT_PROFILE})",
    )
    parser.add_argument(
        "--bin-dir",
        type=Path,
        default=DEFAULT_BIN_DIR,
        help="bobr binaries to build with, put first on PATH "
        f"(default: {DEFAULT_BIN_DIR})",
    )
    args = parser.parse_args()

    _profile_path = args.profile.expanduser().resolve()
    _bin_dir = args.bin_dir.expanduser().resolve()

    mcp.settings.host = args.host
    mcp.settings.port = args.port
    print(
        f"bobr-mcp-local: serving on http://{args.host}:{args.port}/mcp",
        flush=True,
    )
    _report_setup()
    mcp.run(transport="streamable-http")


if __name__ == "__main__":
    main()
