#!/usr/bin/env python3
"""bobr-mcp-local -- a tiny local MCP server that runs bobr builds for the agent.

Why it exists: the Claude Code agent runs under NoNewPrivs=1, which neutralises
the setuid `newuidmap` that bobr's user-namespace sandbox needs, so the agent
cannot run real package builds itself -- and neither could any process it spawns
(NoNewPrivs is inherited). This server is launched by the user in a normal shell
(NoNewPrivs=0), so it CAN build. The agent reaches it over localhost HTTP; since
the server is not a child of the agent, the restriction never applies to it.

It exposes one capability: run `tools/bobr-build.sh <target>` in the user's store
and stream the result back. The single `bobr_build` tool keeps the request open
and streams notable build lines as progress while the build runs (the open call
is the push channel, so even multi-minute builds never time out), then returns a
structured outcome: the exit code, the `done: X built · Y failed` line, the
source hash reported by a placeholder-hash mismatch, any build error, and the
path of the failing sandbox log (which the agent reads itself from the store).

Run it (in a normal, non-no_new_privs shell on the machine that owns the store):

    pip install mcp                                   # one-time
    python3 bobr-recipes/tools/bobr-mcp-local.py      # binds 127.0.0.1:8765

Point Claude Code at it (streamable-http endpoint is /mcp):

    claude mcp add --transport http bobr-local http://127.0.0.1:8765/mcp

Scope: it only ever runs `bobr-build.sh [--dry-run] <target>` (target validated
against [A-Za-z0-9_]+) in the store bobr-build.sh defaults to. It never deletes
or cleans anything, and it serialises builds so two never run at once.
"""

from __future__ import annotations

import argparse
import asyncio
import re
from pathlib import Path

from mcp.server.fastmcp import Context, FastMCP

# tools/bobr-mcp-local.py -> the recipes dir is the parent of tools/.
RECIPES_DIR = Path(__file__).resolve().parent.parent
BUILD_SH = RECIPES_DIR / "tools" / "bobr-build.sh"

TARGET_RE = re.compile(r"^[A-Za-z0-9_]+$")
HASH_RE = re.compile(r"unexpected object hash:.*got ([0-9a-f]{64})")
SUMMARY_RE = re.compile(r"done: .*built.*failed")
ERROR_RE = re.compile(r"error\[build-failed\]:.*")
LOGPATH_RE = re.compile(r"stdout=(\S+\.log)")
NINJA_RE = re.compile(r"\[(\d+)/(\d+)\]")
# Lines worth forwarding as progress; the rest is buffered but not streamed, so
# compile spam does not drown the useful markers.
INTERESTING_RE = re.compile(
    r"(==>|done:|error|ERROR|FAILED|warning:|unexpected object hash|"
    r"Sandbox |Did not find|not found|ERROR:)"
)

mcp = FastMCP("bobr-local")
_build_lock = asyncio.Lock()


@mcp.tool()
async def bobr_build(target: str, ctx: Context, dry_run: bool = False) -> dict:
    """Run `bobr-build.sh <target>` in the user's bobr-store and return the outcome.

    Streams notable build lines as progress while it runs (long builds never time
    out), then returns a structured result. On a placeholder-hash first build,
    `source_hash` carries the real hash to paste into the recipe.

    Args:
        target: bobr recipe attribute, e.g. "gnome_settings_daemon" or
            "test_gnome_rootfs". Must match [A-Za-z0-9_]+.
        dry_run: pass --dry-run (validate and lower the request only, no build).
    """
    if not TARGET_RE.match(target):
        raise ValueError(f"invalid target {target!r}: expected [A-Za-z0-9_]+")
    if not BUILD_SH.is_file():
        raise FileNotFoundError(f"bobr-build.sh not found at {BUILD_SH}")

    argv = [str(BUILD_SH)]
    if dry_run:
        argv.append("--dry-run")
    argv.append(target)

    async with _build_lock:
        await ctx.info(f"$ {' '.join(argv)}")
        proc = await asyncio.create_subprocess_exec(
            *argv,
            cwd=str(RECIPES_DIR),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        assert proc.stdout is not None
        tail: list[str] = []
        async for raw in proc.stdout:
            line = raw.decode("utf-8", "replace").rstrip("\n")
            tail.append(line)
            # Keep only the recent lines: the summary/hash/error land at the end.
            if len(tail) > 800:
                del tail[:400]
            ninja = NINJA_RE.search(line)
            if ninja:
                done, total = int(ninja.group(1)), int(ninja.group(2))
                if total and (done == total or done % 25 == 0):
                    await ctx.report_progress(done, total)
            elif INTERESTING_RE.search(line):
                await ctx.info(line)
        exit_code = await proc.wait()

    text = "\n".join(tail)
    hash_m = HASH_RE.search(text)
    summary_m = SUMMARY_RE.search(text)
    error_m = ERROR_RE.search(text)
    logpath_m = LOGPATH_RE.search(text)
    return {
        "target": target,
        "dry_run": dry_run,
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


def main() -> None:
    parser = argparse.ArgumentParser(description="local bobr build MCP server")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8765)
    args = parser.parse_args()
    mcp.settings.host = args.host
    mcp.settings.port = args.port
    print(
        f"bobr-mcp-local: serving on http://{args.host}:{args.port}/mcp "
        f"(recipes: {RECIPES_DIR})",
        flush=True,
    )
    mcp.run(transport="streamable-http")


if __name__ == "__main__":
    main()
