#!/usr/bin/env bash

# Smoke-test update-fsobj-hashes.sh on file, directory, bulk, and check flows.
# Run this when editing fsobj-hash lock-file tooling or local Source authoring
# behavior.

set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
recipes_root="${workspace_root}/mbuild-recipes"
source_tool="${recipes_root}/tools/update-fsobj-hashes.sh"
fsobj_hash_bin="${workspace_root}/mbuild/target/debug/fsobj-hash"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

(
  cd "${workspace_root}/mbuild"
  cargo build -p fsobj-hash >/dev/null
)

fixture_repo="${tmpdir}/fixture-recipes"
mkdir -p "${fixture_repo}/tools"
cp "${source_tool}" "${fixture_repo}/tools/update-fsobj-hashes.sh"
chmod +x "${fixture_repo}/tools/update-fsobj-hashes.sh"

cat > "${fixture_repo}/env.sh" <<EOF_INNER
#!/usr/bin/env bash
store_rel_from_recipes="../mbuild-store"
env_sh_dir="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
recipes_root="\${env_sh_dir}"
workspace_root="${workspace_root}"
store_root="\${workspace_root}/mbuild-store"
EOF_INNER

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
"${fixture_repo}/tools/update-fsobj-hashes.sh" "${fixture_repo}/hello.txt"
assert_file_equals "${fixture_repo}/hello.txt.fsobj-hash" "${file_hash}"
"${fixture_repo}/tools/update-fsobj-hashes.sh" --check "${fixture_repo}/hello.txt"

mkdir -p "${fixture_repo}/tree/subdir"
printf 'payload\n' > "${fixture_repo}/tree/subdir/file.txt"
dir_hash="$("${fsobj_hash_bin}" "${fixture_repo}/tree" | tr -d '\r\n')"
"${fixture_repo}/tools/update-fsobj-hashes.sh" "${fixture_repo}/tree"
assert_file_equals "${fixture_repo}/tree.fsobj-hash" "${dir_hash}"

printf '%s\n' '0000000000000000000000000000000000000000000000000000000000000000' > "${fixture_repo}/hello.txt.fsobj-hash"
expect_failure "${fixture_repo}/tools/update-fsobj-hashes.sh" --check "${fixture_repo}/hello.txt"

printf '%s\n' 'stale' > "${fixture_repo}/tree.fsobj-hash"
printf '%s\n' 'stale' > "${fixture_repo}/hello.txt.fsobj-hash"
"${fixture_repo}/tools/update-fsobj-hashes.sh"
assert_file_equals "${fixture_repo}/hello.txt.fsobj-hash" "${file_hash}"
assert_file_equals "${fixture_repo}/tree.fsobj-hash" "${dir_hash}"

printf '%s\n' 'orphan' > "${fixture_repo}/missing.fsobj-hash"
expect_failure "${fixture_repo}/tools/update-fsobj-hashes.sh" --check

echo "update-fsobj-hashes smoke tests passed"
