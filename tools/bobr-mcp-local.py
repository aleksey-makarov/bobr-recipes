#!/usr/bin/env python3
"""bobr-mcp-local -- a tiny local MCP server that runs bobr builds for the agent.

Why it exists: the Claude Code agent runs under NoNewPrivs=1, which neutralises
the setuid `newuidmap` that bobr's user-namespace sandbox needs, so the agent
cannot run real package builds itself -- and neither could any process it spawns
(NoNewPrivs is inherited). This server is launched by the user in a normal shell
(NoNewPrivs=0), so it CAN build. The agent reaches it over localhost HTTP; since
the server is not a child of the agent, the restriction never applies to it.

It exposes two capabilities: start
`bin/bobr-build.sh <profile> --target <target>` as an in-memory background job,
and inspect that job's status. No MCP tool call remains open for the lifetime of
a build, so a client-side request deadline cannot interrupt a multi-hour build.
The final status includes the exit code, the `done: X built · Y failed` line,
the source hash reported by a placeholder-hash mismatch, any build error, and
the path of the failing sandbox log (which the agent reads itself from the
store).

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
two never run at once. Job status is deliberately kept only in memory: restart
the server and the old job ids cease to exist.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import re
import shutil
import subprocess
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path

from mcp.server.fastmcp import FastMCP

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
MAX_WAIT_SECONDS = 240
# Lines worth retaining as notable status; the complete recent tail is kept
# separately for final diagnostics.
INTERESTING_RE = re.compile(
    r"(==>|done:|error|ERROR|FAILED|warning:|unexpected object hash|"
    r"Sandbox |Did not find|not found|ERROR:)"
)

mcp = FastMCP("bobr-local")
_build_lock = asyncio.Lock()


@dataclass
class BuildJob:
    """In-memory state for one build started by an MCP call."""

    job_id: str
    target: str
    dry_run: bool
    jobs: int | None
    argv: list[str]
    state: str = "queued"
    created_at: float = field(default_factory=time.time)
    started_at: float | None = None
    finished_at: float | None = None
    last_output: str = ""
    tail: list[str] = field(default_factory=list)
    notable: list[str] = field(default_factory=list)
    progress_done: int | None = None
    progress_total: int | None = None
    result: dict | None = None
    task: asyncio.Task[None] | None = field(default=None, repr=False)


_jobs: dict[str, BuildJob] = {}

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


async def _stream_stderr(stream: asyncio.StreamReader, job: BuildJob) -> None:
    """Buffer diagnostics and update the status visible to polling clients."""
    async for raw in stream:
        line = raw.decode("utf-8", "replace").rstrip("\n")
        job.tail.append(line)
        job.last_output = line
        # Keep only the recent lines: the summary/hash/error land at the end.
        if len(job.tail) > 800:
            del job.tail[:400]
        ninja = NINJA_RE.search(line)
        if ninja:
            job.progress_done = int(ninja.group(1))
            job.progress_total = int(ninja.group(2))
        if ninja or INTERESTING_RE.search(line):
            job.notable.append(line)
            if len(job.notable) > 100:
                del job.notable[:50]


async def _read_stdout(stream: asyncio.StreamReader) -> str:
    return (await stream.read()).decode("utf-8", "replace")


def _build_argv(target: str, dry_run: bool, jobs: int | None) -> list[str]:
    """Validate a build request and return its fixed command line."""
    if not TARGET_RE.match(target):
        raise ValueError(f"invalid target {target!r}: expected [A-Za-z0-9_]+")
    if jobs is not None and jobs < 1:
        raise ValueError(f"invalid jobs {jobs!r}: expected a positive integer")
    if not BUILD_SH.is_file():
        raise FileNotFoundError(f"bobr-build.sh not found at {BUILD_SH}")
    if not _profile_path.is_file():
        raise FileNotFoundError(
            f"no build profile at {_profile_path}; create one importing "
            f"{RECIPES_DIR / 'build-profile' / 'bobr-user.ncl'}, or start "
            f"this server with --profile"
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
    return argv


def _parse_result(job: BuildJob, exit_code: int, stdout_text: str) -> dict:
    """Turn buffered process output into the public final result."""
    text = "\n".join(job.tail)
    hash_m = HASH_RE.search(text)
    summary_m = SUMMARY_RE.search(text)
    error_m = ERROR_RE.search(text)
    logpath_m = LOGPATH_RE.search(text)

    result = {
        "target": job.target,
        "profile": str(_profile_path),
        "dry_run": job.dry_run,
        "jobs": job.jobs,
        "exit_code": exit_code,
        "ok": exit_code == 0,
        "summary": summary_m.group(0) if summary_m else None,
        # Real fsobj-hash from a placeholder-hash build; paste it into the recipe.
        "source_hash": hash_m.group(1) if hash_m else None,
        "error": error_m.group(0) if error_m else None,
        # Path of the failing sandbox step log; the agent reads it from the store.
        "failed_log": logpath_m.group(1) if logpath_m else None,
        "tail": job.tail[-40:],
    }

    if job.dry_run:
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


async def _run_job(job: BuildJob) -> None:
    """Run one queued build and retain all status needed by later MCP calls."""
    try:
        async with _build_lock:
            job.state = "running"
            job.started_at = time.time()
            proc = await asyncio.create_subprocess_exec(
                *job.argv,
                cwd=str(RECIPES_DIR),
                env=_child_env(),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            assert proc.stdout is not None and proc.stderr is not None
            stdout_text, _ = await asyncio.gather(
                _read_stdout(proc.stdout),
                _stream_stderr(proc.stderr, job),
            )
            exit_code = await proc.wait()
            job.result = _parse_result(job, exit_code, stdout_text)
            job.state = "succeeded" if exit_code == 0 else "failed"
    except asyncio.CancelledError:
        job.state = "failed"
        job.result = {
            "target": job.target,
            "ok": False,
            "error": "MCP server stopped while the build job was active",
            "tail": job.tail[-40:],
        }
        raise
    except Exception as error:
        job.state = "failed"
        job.result = {
            "target": job.target,
            "profile": str(_profile_path),
            "dry_run": job.dry_run,
            "jobs": job.jobs,
            "ok": False,
            "error": f"could not run build: {error}",
            "tail": job.tail[-40:],
        }
    finally:
        job.finished_at = time.time()


@mcp.tool()
async def bobr_build_start(
    target: str,
    dry_run: bool = False,
    jobs: int | None = None,
    wait_seconds: int = 0,
) -> dict:
    """Start a serialized bobr build and optionally wait for its result.

    With the default zero wait the call returns immediately. A positive wait
    returns as soon as the build finishes, or returns its current status when
    the wait expires. Expiry never cancels the background build.

    Args:
        target: bobr recipe attribute. Must match [A-Za-z0-9_]+.
        dry_run: pass --dry-run (validate and lower the request only, no build).
        jobs: cap concurrent builders; the default is one per core.
        wait_seconds: wait up to this many seconds for completion; 0 returns
            immediately, and the maximum is 240 seconds.
    """
    _validate_wait_seconds(wait_seconds)
    argv = _build_argv(target, dry_run, jobs)
    job_id = (
        f"{time.strftime('%Y%m%d-%H%M%S')}-{target}-{uuid.uuid4().hex[:8]}"
    )
    job = BuildJob(
        job_id=job_id,
        target=target,
        dry_run=dry_run,
        jobs=jobs,
        argv=argv,
    )
    _jobs[job_id] = job
    job.task = asyncio.create_task(_run_job(job), name=f"bobr-build:{job_id}")
    print(
        "bobr-mcp-local: build start: "
        f"target={target} dry_run={str(dry_run).lower()} "
        f"jobs={jobs if jobs is not None else 'default'} "
        f"wait={wait_seconds}s job={job_id}",
        flush=True,
    )
    return await _wait_for_job(job, wait_seconds)


@mcp.tool()
async def bobr_build_status(job_id: str, wait_seconds: int = 0) -> dict:
    """Return build status, optionally waiting for the final result.

    Args:
        job_id: id returned by `bobr_build_start`.
        wait_seconds: wait up to this many seconds for completion; 0 returns
            immediately, and the maximum is 240 seconds. Expiry does not cancel
            the build.
    """
    _validate_wait_seconds(wait_seconds)
    job = _jobs.get(job_id)
    if job is None:
        raise ValueError(
            f"unknown build job {job_id!r}; the server may have been restarted"
        )
    return await _wait_for_job(job, wait_seconds)


def _validate_wait_seconds(wait_seconds: int) -> None:
    if not 0 <= wait_seconds <= MAX_WAIT_SECONDS:
        raise ValueError(
            f"invalid wait_seconds {wait_seconds!r}: expected an integer "
            f"from 0 through {MAX_WAIT_SECONDS}"
        )


async def _wait_for_job(job: BuildJob, wait_seconds: int) -> dict:
    """Wait without transferring cancellation to the background build."""
    if wait_seconds > 0 and job.task is not None and not job.task.done():
        try:
            await asyncio.wait_for(
                asyncio.shield(job.task), timeout=wait_seconds
            )
        except TimeoutError:
            pass
    return _job_status(job)


def _job_status(job: BuildJob) -> dict:
    """Take one consistent, serializable snapshot of an in-memory job."""

    now = job.finished_at or time.time()
    status = {
        "job_id": job.job_id,
        "state": job.state,
        "target": job.target,
        "dry_run": job.dry_run,
        "jobs": job.jobs,
        "elapsed_seconds": round(now - (job.started_at or job.created_at), 1),
        "last_output": job.last_output or None,
        "notable": job.notable[-20:],
    }
    if job.started_at is None:
        status["queued_seconds"] = round(now - job.created_at, 1)
    if job.progress_total is not None:
        status["progress"] = {
            "done": job.progress_done,
            "total": job.progress_total,
        }
    if job.result is not None:
        status.update(job.result)
    return status


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
    # The low-level server otherwise prints the same generic line for every
    # tool call. Build starts have a concise, useful line of their own above.
    logging.getLogger("mcp.server.lowlevel.server").setLevel(logging.WARNING)
    mcp.run(transport="streamable-http")


if __name__ == "__main__":
    main()
