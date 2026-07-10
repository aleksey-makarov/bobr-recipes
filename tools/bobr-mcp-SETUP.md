# bobr-mcp build broker — setup

`tools/bobr-mcp.py` is an MCP server that lets the agent build bobr and the
recipes on an **unrestricted host**. The agent's own environment sets
`no_new_privs`, which blocks the setuid `newuidmap` that bobr's sandbox needs
for its user-namespace id mapping, so real (Meson/Autotools/Sandbox) builds
cannot run there. The broker runs where they can; the agent drives it over MCP
and edits the source trees directly over sshfs.

## Model

- The build host has, per repo, a **clone checked out to branch `agent`**,
  arranged as an "agent workspace" with sibling directories:

  ```
  $AGENT/
    bobr/          clone of bobr,    branch agent
    bobr-recipes/  clone of recipes, branch agent
    bobr-store/    build store
  ```

  The names `bobr` / `bobr-recipes` / `bobr-store` must be siblings —
  `bobr-build.sh` resolves the bobr binary and store relative to the recipes
  path.
- That workspace is sshfs-mounted to the agent, which edits it with its own
  tools. The broker only execs and commits; it has no filesystem tools.
- git is confined to these two clones and to branch `agent`: commit / restore /
  push happen only there, never on master, never `--force`, never a merge.
  Merging `agent` → master is the user's job.

## 1. Prepare the workspace (on the build host)

```sh
AGENT=/srv/mbuild-agent            # pick a path; export it for the broker
mkdir -p "$AGENT/bobr-store"

git clone <origin> "$AGENT/bobr"
git -C "$AGENT/bobr" checkout -B agent

git clone <origin> "$AGENT/bobr-recipes"
git -C "$AGENT/bobr-recipes" checkout -B agent
```

`<origin>` is your shared remote (or the master machine over ssh). Keep the
`agent` branch in step with master via your own remote (`git fetch` +
`git merge origin/master` inside the `agent` clones); the broker does not do it.

## 2. Dependencies

Python ≥ 3.10 and the `mcp` SDK (FastMCP). On nix, either:

```sh
nix-shell -p "python3.withPackages(ps: [ ps.mcp ])"      # if packaged
# or a venv:
python3 -m venv ~/.venv/bobr-mcp && . ~/.venv/bobr-mcp/bin/activate && pip install mcp
```

## 3. Run the broker (on the build host)

```sh
BOBR_MCP_AGENT=/srv/mbuild-agent python3 /srv/mbuild-agent/bobr-recipes/tools/bobr-mcp.py
```

It listens on `127.0.0.1:8765` by default. Env knobs:

| var | default | meaning |
|-----|---------|---------|
| `BOBR_MCP_AGENT` | (required) | agent workspace root |
| `BOBR_MCP_BOBR_BIN` | `$AGENT/bobr/target/debug/bobr` | bobr binary recipe builds use |
| `BOBR_MCP_HOST` | `127.0.0.1` | bind host |
| `BOBR_MCP_PORT` | `8765` | bind port |

## 4. Reach it from the machine running Claude Code

Keep the broker on loopback and tunnel to it (recommended):

```sh
ssh -N -L 8765:127.0.0.1:8765 <build-host>
```

## 5. Register with Claude Code

```sh
claude mcp add --transport http bobr-mcp http://127.0.0.1:8765/mcp
```

or in `.mcp.json`:

```json
{ "mcpServers": { "bobr-mcp": { "type": "http", "url": "http://127.0.0.1:8765/mcp" } } }
```

FastMCP serves the streamable-HTTP transport under `/mcp`.

## 6. Verify, then build

1. `broker_info` — confirm `no_new_privs == 0` (otherwise builds will fail),
   the paths resolve, and both repos are on `agent`.
2. `bobr_compile` — build the bobr binary (until this runs, `bobr_bin_exists`
   is false).
3. `recipe_build(attr, jobs=…)` — returns a `job_id`.
4. `job_status(job_id)` — poll; on failure read `fail_log_dir` from the store
   (over sshfs) and iterate.

## Tools

- exec (async, return `job_id`): `bobr_compile`, `cargo`, `recipe_build`
- jobs: `job_status`, `job_logs`, `job_cancel`, `jobs_list`
- git (branch `agent` only): `git_status`, `git_diff`, `git_log`, `git_commit`,
  `git_restore`, `git_push`
- `broker_info`

## Security

- Reach the broker over the ssh tunnel (loopback), or bind a trusted interface
  only. There is no built-in auth token.
- `attr` is restricted to `[A-Za-z0-9_]+`; `cargo` to `build/test/clippy/fmt/
  check`; no arbitrary shell. git mutations are refused unless HEAD is `agent`.
  Store deletion/GC is not exposed.
