#!/usr/bin/env bash

# Refresh adjacent `*.fsobj-hash` lock files for local Source inputs.
#
# Usage:
# - `tools/bobr-update-fsobj-hashes.sh`
#   recursively updates every `*.fsobj-hash` file under `bobr-recipes`
#   whose sibling path without the suffix exists as a file or directory
# - `tools/bobr-update-fsobj-hashes.sh <path>`
#   writes or updates the sibling `<path>.fsobj-hash` for one file or directory
# - `tools/bobr-update-fsobj-hashes.sh --check [<path>]`
#   verifies existing lock files without rewriting them
#
# A directory Source containing an empty subdirectory is rejected with an error
# (in every mode): git cannot store empty dirs, so its lock would never match a
# fresh checkout and each build would keep rewriting it.
#
# The fsobj-hash binary defaults to the local debug build; override it with
# `--fsobj-hash=PATH` or the `BOBR_FSOBJ_HASH` environment variable (bobr-build.sh
# passes the binary it resolved next to `bobr`).

set -euo pipefail

if [ "$#" -gt 3 ]; then
  echo "usage: $0 [--check] [--fsobj-hash=PATH] [path]" >&2
  exit 2
fi

check_only=0
target_path=""
fsobj_hash_override=""
for arg in "$@"; do
  case "$arg" in
    --check)
      check_only=1
      ;;
    --fsobj-hash=*)
      fsobj_hash_override="${arg#--fsobj-hash=}"
      ;;
    -*)
      echo "unknown option: $arg" >&2
      exit 2
      ;;
    *)
      if [ -n "${target_path}" ]; then
        echo "usage: $0 [--check] [--fsobj-hash=PATH] [path]" >&2
        exit 2
      fi
      target_path="$arg"
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$(cd "${repo_root}/.." && pwd)"
fsobj_hash_bin="${fsobj_hash_override:-${BOBR_FSOBJ_HASH:-${workspace_root}/bobr/target/debug/fsobj-hash}}"

if [ ! -x "${fsobj_hash_bin}" ]; then
  echo "missing fsobj-hash binary: ${fsobj_hash_bin}" >&2
  echo "build it first with: cargo build -p fsobj-hash" >&2
  exit 1
fi

hash_for_path() {
  local path="$1"
  "${fsobj_hash_bin}" "${path}" | tr -d '\r\n'
}

write_or_check_lock() {
  local peer_path="$1"
  local lock_path="$2"
  local hash
  local expected
  local current=""

  if [ ! -e "${peer_path}" ]; then
    echo "missing peer path for lock file: ${peer_path}" >&2
    return 1
  fi
  if [ ! -f "${peer_path}" ] && [ ! -d "${peer_path}" ]; then
    echo "peer path is neither file nor directory: ${peer_path}" >&2
    return 1
  fi

  # Reject empty directories in a source tree: git does not track empty dirs, so
  # a lock computed over one never matches a fresh checkout, and every build
  # rewrites the lock (dirtying the tree). Declare a genuinely-needed empty dir
  # in the recipe as a Tree `{type="dir"}` entry instead of shipping it here.
  if [ -d "${peer_path}" ]; then
    local empty_dirs
    empty_dirs="$(find "${peer_path}" -type d -empty)"
    if [ -n "${empty_dirs}" ]; then
      {
        echo "empty directories under '${peer_path}' are not reproducible from git"
        echo "(git does not track them, so the lock would never match a fresh checkout):"
        printf '%s\n' "${empty_dirs}" | sed 's/^/  /'
        echo "remove them, or declare a needed empty dir in the recipe (Tree {type=\"dir\"})."
      } >&2
      return 1
    fi
  fi

  hash="$(hash_for_path "${peer_path}")"
  expected="${hash}"$'\n'

  if [ -f "${lock_path}" ]; then
    current="$(cat "${lock_path}")"$'\n'
  fi

  if [ "${check_only}" -eq 1 ]; then
    if [ ! -f "${lock_path}" ]; then
      echo "missing lock file: ${lock_path}" >&2
      return 1
    fi
    if [ "${current}" != "${expected}" ]; then
      echo "stale lock file: ${lock_path}" >&2
      return 1
    fi
    return 0
  fi

  if [ "${current}" != "${expected}" ]; then
    printf '%s' "${expected}" > "${lock_path}"
    echo "updated ${lock_path}" >&2
  fi
}

if [ -n "${target_path}" ]; then
  peer_path="$(realpath -m "${target_path}")"
  lock_path="${peer_path}.fsobj-hash"
  write_or_check_lock "${peer_path}" "${lock_path}"
  exit 0
fi

status=0
while IFS= read -r -d '' lock_path; do
  peer_path="${lock_path%.fsobj-hash}"
  if ! write_or_check_lock "${peer_path}" "${lock_path}"; then
    status=1
  fi
done < <(find "${repo_root}" -type f -name '*.fsobj-hash' -print0 | sort -z)

exit "${status}"
