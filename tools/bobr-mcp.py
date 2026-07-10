#!/usr/bin/env python3
"""bobr-mcp -- MCP build broker.

Runs on an UNRESTRICTED build host (the agent's own environment sets
`no_new_privs`, which blocks the setuid `newuidmap` that bobr's sandbox needs,
so the agent cannot build there). The broker exposes async build/cargo jobs,
job inspection, and git limited to the `agent` branch. It operates on the
"agent workspace" -- a directory holding sibling clones checked out to branch
`agent`:

    $BOBR_MCP_AGENT/
      bobr/          (clone of bobr,    branch agent)
      bobr-recipes/  (clone of recipes, branch agent)
      bobr-store/    (build store)

The agent edits that workspace over sshfs with its own tools; the broker only
execs and commits. It has NO filesystem tools by design.

Security: bind to loopback and reach it over an ssh tunnel (recommended), or to
a trusted interface. git is confined to the two clones and to branch `agent`
(commit/restore/push only there; never master, no --force, no merge).

Config (env):
  BOBR_MCP_AGENT     agent workspace root (required)
  BOBR_MCP_BOBR_BIN  bobr binary for recipe builds
                     (default: $AGENT/bobr/target/debug/bobr)
  BOBR_MCP_HOST      bind host (default 127.0.0.1)
  BOBR_MCP_PORT      bind port (default 8765)

Run:  BOBR_MCP_AGENT=/srv/mbuild-agent python3 bobr-mcp.py
Deps: the `mcp` Python SDK (FastMCP).
"""

from __future__ import annotations

import os
import re
import signal
import subprocess
import threading
import time
import uuid
from pathlib import Path

from mcp.server.fastmcp import FastMCP

# --- configuration ---------------------------------------------------------

AGENT = Path(os.environ["BOBR_MCP_AGENT"]).resolve()
BOBR_REPO = AGENT / "bobr"
RECIPES = AGENT / "bobr-recipes"
STORE = AGENT / "bobr-store"
BOBR_BIN = Path(os.environ.get("BOBR_MCP_BOBR_BIN", BOBR_REPO / "target/debug/bobr"))
JOB_LOG_DIR = AGENT / ".bobr-mcp"

AGENT_BRANCH = "agent"  # hardcoded: git mutations are refused off this branch
ATTR_RE = re.compile(r"^[A-Za-z0-9_]+$")
CARGO_SUBCOMMANDS = {"build", "test", "clippy", "fmt", "check"}
REPOS = {"bobr": BOBR_REPO, "bobr-recipes": RECIPES, "recipes": RECIPES}

HOST = os.environ.get("BOBR_MCP_HOST", "127.0.0.1")
PORT = int(os.environ.get("BOBR_MCP_PORT", "8765"))

mcp = FastMCP("bobr-mcp", host=HOST, port=PORT)

# --- job registry ----------------------------------------------------------


class Job:
    def __init__(self, kind: str, label: str, argv: list[str], cwd: Path):
        self.id = uuid.uuid4().hex[:8]
        self.kind = kind
        self.label = label
        self.argv = argv
        self.cwd = str(cwd)
        self.started_at = time.time()
        self.finished_at: float | None = None
        JOB_LOG_DIR.mkdir(parents=True, exist_ok=True)
        self.log_path = JOB_LOG_DIR / f"{self.id}.log"
        self._fh = open(self.log_path, "wb")
        self.proc = subprocess.Popen(
            argv, cwd=self.cwd, stdout=self._fh, stderr=subprocess.STDOUT,
            start_new_session=True,
        )

    def poll(self) -> int | None:
        rc = self.proc.poll()
        if rc is not None and self.finished_at is None:
            self.finished_at = time.time()
            try:
                self._fh.close()
            except Exception:
                pass
        return rc

    def state(self) -> str:
        rc = self.poll()
        if rc is None:
            return "running"
        return "succeeded" if rc == 0 else "failed"

    def read_log(self) -> str:
        try:
            return self.log_path.read_text(errors="replace")
        except FileNotFoundError:
            return ""


_JOBS: dict[str, Job] = {}
_LOCK = threading.Lock()


def _start(kind: str, label: str, argv: list[str], cwd: Path) -> dict:
    job = Job(kind, label, argv, cwd)
    with _LOCK:
        _JOBS[job.id] = job
    return {"job_id": job.id, "kind": kind, "label": label}


def _get(job_id: str) -> Job:
    with _LOCK:
        job = _JOBS.get(job_id)
    if job is None:
        raise ValueError(f"unknown job_id: {job_id}")
    return job


# --- build-output parsing --------------------------------------------------


def _parse(text: str) -> dict:
    out: dict = {}
    m = re.search(r"done:\s+(\d+) built\D+?(\d+) cache-hit\D+?(\d+) failed", text)
    if m:
        out["counts"] = {
            "built": int(m.group(1)),
            "cache_hit": int(m.group(2)),
            "failed": int(m.group(3)),
        }
        h = re.search(r"[0-9a-f]{64}", text[m.end():])
        if h:
            out["object_hash"] = h.group(0)
    tim: dict = {}
    mn = re.search(r"nickel recipes -> json request:\s+([\d.]+)s", text)
    if mn:
        tim["nickel_s"] = float(mn.group(1))
    mb = re.search(r"bobr build:\s+([\d.]+)s", text)
    if mb:
        tim["bobr_s"] = float(mb.group(1))
    if tim:
        out["timings"] = tim
    mf = re.search(r"stdout=(\S+/raw)/", text)
    if mf:
        out["fail_log_dir"] = mf.group(1)
    return out


def _tail(text: str, n: int) -> str:
    return "\n".join(text.splitlines()[-n:])


# --- git helpers -----------------------------------------------------------


def _repo(repo: str) -> Path:
    path = REPOS.get(repo)
    if path is None:
        raise ValueError(f"unknown repo '{repo}' (use 'bobr' or 'bobr-recipes')")
    return path


def _git(path: Path, *args: str) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["git", "-C", str(path), *args],
        capture_output=True, text=True,
    )


def _assert_agent(path: Path) -> None:
    r = _git(path, "symbolic-ref", "--short", "HEAD")
    branch = r.stdout.strip()
    if r.returncode != 0 or branch != AGENT_BRANCH:
        raise ValueError(
            f"refusing git mutation: {path} is on '{branch or '(detached)'}', "
            f"not '{AGENT_BRANCH}'"
        )


# --- tools: exec (async jobs) ----------------------------------------------


@mcp.tool()
def bobr_compile(profile: str = "debug") -> dict:
    """Rebuild the bobr binary (cargo build --bin bobr) so recipe builds use
    the current bobr sources. profile: 'debug' or 'release'."""
    argv = ["cargo", "build", "--bin", "bobr"]
    if profile == "release":
        argv.append("--release")
    elif profile != "debug":
        raise ValueError("profile must be 'debug' or 'release'")
    return _start("bobr_compile", f"cargo build --bin bobr ({profile})", argv, BOBR_REPO)


@mcp.tool()
def cargo(args: list[str]) -> dict:
    """Run cargo in the bobr repo. Allowed subcommands: build, test, clippy,
    fmt, check. Example: cargo(["test", "-p", "fsobj-hash"])."""
    if not args or args[0] not in CARGO_SUBCOMMANDS:
        raise ValueError(f"first arg must be one of {sorted(CARGO_SUBCOMMANDS)}")
    return _start("cargo", "cargo " + " ".join(args), ["cargo", *args], BOBR_REPO)


@mcp.tool()
def recipe_build(attr: str, jobs: int | None = None) -> dict:
    """Build one pkgs.ncl attribute via tools/bobr-build.sh into the agent
    store, using the compiled bobr binary. Returns a job_id; poll job_status."""
    if not ATTR_RE.match(attr):
        raise ValueError("attr must match [A-Za-z0-9_]+")
    argv = [
        str(RECIPES / "tools/bobr-build.sh"),
        "--store", str(STORE),
        "--bobr", str(BOBR_BIN),
    ]
    if jobs is not None:
        argv += ["--jobs", str(int(jobs))]
    argv.append(attr)
    return _start("recipe_build", f"build {attr}", argv, RECIPES)


# --- tools: job inspection -------------------------------------------------


@mcp.tool()
def job_status(job_id: str) -> dict:
    """State of a job plus parsed build summary (counts, object_hash, timings,
    fail_log_dir) and a short tail."""
    job = _get(job_id)
    text = job.read_log()
    result: dict = {
        "job_id": job.id,
        "kind": job.kind,
        "label": job.label,
        "state": job.state(),
        "exit_code": job.proc.poll(),
        "duration_s": round((job.finished_at or time.time()) - job.started_at, 1),
        "tail": _tail(text, 40),
    }
    result.update(_parse(text))
    return result


@mcp.tool()
def job_logs(job_id: str, tail_lines: int = 100) -> str:
    """Tail of a job's captured stdout+stderr."""
    return _tail(_get(job_id).read_log(), tail_lines)


@mcp.tool()
def job_cancel(job_id: str) -> dict:
    """Kill a running job (its whole process group)."""
    job = _get(job_id)
    if job.poll() is None:
        try:
            os.killpg(job.proc.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    return {"job_id": job.id, "state": job.state()}


@mcp.tool()
def jobs_list() -> list[dict]:
    """All known jobs, newest first."""
    with _LOCK:
        jobs = sorted(_JOBS.values(), key=lambda j: j.started_at, reverse=True)
    return [
        {"job_id": j.id, "kind": j.kind, "label": j.label,
         "state": j.state(), "started_at": j.started_at}
        for j in jobs
    ]


# --- tools: git (agent branch only) ----------------------------------------


@mcp.tool()
def git_status(repo: str) -> str:
    """`git status --short --branch` in the given repo (bobr | bobr-recipes)."""
    return _git(_repo(repo), "status", "--short", "--branch").stdout


@mcp.tool()
def git_diff(repo: str, staged: bool = False) -> str:
    """`git diff` (or --staged) in the given repo."""
    args = ["diff"] + (["--staged"] if staged else [])
    return _git(_repo(repo), *args).stdout


@mcp.tool()
def git_log(repo: str, n: int = 10) -> str:
    """Recent commits (oneline) in the given repo."""
    return _git(_repo(repo), "log", f"-{int(n)}", "--oneline").stdout


@mcp.tool()
def git_commit(repo: str, message: str) -> dict:
    """Stage all changes and commit on branch `agent` (refused on any other
    branch). `message` is used verbatim."""
    path = _repo(repo)
    _assert_agent(path)
    _git(path, "add", "-A")
    r = _git(path, "commit", "-m", message)
    if r.returncode != 0:
        return {"committed": False, "output": (r.stdout + r.stderr).strip()}
    head = _git(path, "rev-parse", "--short", "HEAD").stdout.strip()
    return {"committed": True, "commit": head}


@mcp.tool()
def git_restore(repo: str, paths: list[str] | None = None) -> dict:
    """Discard uncommitted changes to tracked files on branch `agent`
    (refused elsewhere). paths=None restores everything."""
    path = _repo(repo)
    _assert_agent(path)
    targets = paths if paths else ["."]
    r = _git(path, "checkout", "--", *targets)
    return {"restored": r.returncode == 0, "output": (r.stdout + r.stderr).strip()}


@mcp.tool()
def git_push(repo: str) -> dict:
    """Push branch `agent` to origin (only agent; refused on any other
    branch)."""
    path = _repo(repo)
    _assert_agent(path)
    r = _git(path, "push", "origin", f"{AGENT_BRANCH}:{AGENT_BRANCH}")
    return {"pushed": r.returncode == 0, "output": (r.stdout + r.stderr).strip()}


# --- tools: sanity ---------------------------------------------------------


@mcp.tool()
def broker_info() -> dict:
    """Resolved paths, whether the bobr binary exists, the no_new_privs bit
    (should be 0 -- else builds will fail), and each repo's current branch."""
    nnp = None
    try:
        for line in Path("/proc/self/status").read_text().splitlines():
            if line.startswith("NoNewPrivs:"):
                nnp = int(line.split()[1])
    except Exception:
        pass
    branches = {}
    for name, path in {"bobr": BOBR_REPO, "bobr-recipes": RECIPES}.items():
        branches[name] = _git(path, "symbolic-ref", "--short", "HEAD").stdout.strip()
    return {
        "agent_workspace": str(AGENT),
        "recipes": str(RECIPES),
        "bobr_repo": str(BOBR_REPO),
        "store": str(STORE),
        "bobr_bin": str(BOBR_BIN),
        "bobr_bin_exists": BOBR_BIN.exists(),
        "no_new_privs": nnp,
        "branches": branches,
        "agent_branch": AGENT_BRANCH,
    }


if __name__ == "__main__":
    mcp.run(transport="streamable-http")
