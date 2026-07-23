#!/usr/bin/env bash

# Smoke-test bobr-update-fsobj-hashes.sh on file, directory, bulk, and check flows.
# Run this when editing fsobj-hash lock-file tooling or local Source authoring
# behavior.

set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
recipes_root="${workspace_root}/bobr-recipes"
source_tool="${recipes_root}/tools/bobr-update-fsobj-hashes.sh"
fsobj_hash_bin="${workspace_root}/bobr/target/debug/fsobj-hash"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

(
  cd "${workspace_root}/bobr"
  cargo build -p fsobj-hash >/dev/null
)

fixture_repo="${tmpdir}/fixture-recipes"
mkdir -p "${fixture_repo}/tools"
tool="${fixture_repo}/tools/bobr-update-fsobj-hashes.sh"
cp "${source_tool}" "${tool}"
chmod +x "${tool}"

# The tool's default fsobj-hash path is derived from its own location, which
# would point inside the fixture; pass the real binary explicitly.
run_tool() { "${tool}" --fsobj-hash="${fsobj_hash_bin}" "$@"; }

assert_file_equals() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(cat "${path}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "unexpected contents in ${path}" >&2
    echo "expected: ${expected}" >&2
    echo "actual:   ${actual}" >&2
    exit 1
  fi
}

expect_failure() {
  if "$@"; then
    echo "expected failure: $*" >&2
    exit 1
  fi
}

printf 'hello world\n' > "${fixture_repo}/hello.txt"
file_hash="$("${fsobj_hash_bin}" "${fixture_repo}/hello.txt" | tr -d '\r\n')"
run_tool "${fixture_repo}/hello.txt"
assert_file_equals "${fixture_repo}/hello.txt.fsobj-hash" "${file_hash}"
run_tool --check "${fixture_repo}/hello.txt"

mkdir -p "${fixture_repo}/tree/subdir"
printf 'payload\n' > "${fixture_repo}/tree/subdir/file.txt"
dir_hash="$("${fsobj_hash_bin}" "${fixture_repo}/tree" | tr -d '\r\n')"
run_tool "${fixture_repo}/tree"
assert_file_equals "${fixture_repo}/tree.fsobj-hash" "${dir_hash}"

printf '%s\n' '0000000000000000000000000000000000000000000000000000000000000000' > "${fixture_repo}/hello.txt.fsobj-hash"
expect_failure run_tool --check "${fixture_repo}/hello.txt"

printf '%s\n' 'stale' > "${fixture_repo}/tree.fsobj-hash"
printf '%s\n' 'stale' > "${fixture_repo}/hello.txt.fsobj-hash"
run_tool
assert_file_equals "${fixture_repo}/hello.txt.fsobj-hash" "${file_hash}"
assert_file_equals "${fixture_repo}/tree.fsobj-hash" "${dir_hash}"

printf '%s\n' 'orphan' > "${fixture_repo}/missing.fsobj-hash"
expect_failure run_tool --check

# Empty directories are not reproducible from git; a directory Source that holds
# one is rejected, even when it also has real files.
mkdir -p "${fixture_repo}/emptytree/present" "${fixture_repo}/emptytree/hollow"
printf 'x\n' > "${fixture_repo}/emptytree/present/keep.txt"
expect_failure run_tool "${fixture_repo}/emptytree"

echo "update-fsobj-hashes smoke tests passed"
