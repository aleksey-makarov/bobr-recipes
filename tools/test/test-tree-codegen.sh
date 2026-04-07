#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
generator="${repo_root}/tools/generate-tree-modules.py"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

python3 "${generator}" --check

fixture_repo="${tmpdir}/fixtures"
mkdir -p "${fixture_repo}/pkg-tree-src/etc" "${fixture_repo}/pkg-tree-src/dev"
printf 'hello tree\n' > "${fixture_repo}/pkg-tree-src/etc/hostname"
printf '#!/bin/sh\nexit 0\n' > "${fixture_repo}/pkg-tree-src/init"
chmod 0755 "${fixture_repo}/pkg-tree-src/init"
ln -s usr/bin "${fixture_repo}/pkg-tree-src/bin"
ln -s /proc/self/mounts "${fixture_repo}/pkg-tree-src/etc/mtab"
ln -s missing-target "${fixture_repo}/pkg-tree-src/etc/broken"

python3 "${generator}" --repo-root "${fixture_repo}"

generated="${fixture_repo}/pkg-tree.ncl"
test -f "${generated}"
grep -F 'path = "etc/hostname"' "${generated}" >/dev/null
grep -F 'path = "init"' "${generated}" >/dev/null
grep -F 'executable = true' "${generated}" >/dev/null
grep -F 'type = "dir"' "${generated}" >/dev/null
grep -F 'path = "dev"' "${generated}" >/dev/null
grep -F 'type = "symlink"' "${generated}" >/dev/null
grep -F 'path = "bin"' "${generated}" >/dev/null
grep -F 'target = "usr/bin"' "${generated}" >/dev/null
grep -F 'path = "etc/mtab"' "${generated}" >/dev/null
grep -F 'target = "/proc/self/mounts"' "${generated}" >/dev/null
grep -F 'path = "etc/broken"' "${generated}" >/dev/null
grep -F 'target = "missing-target"' "${generated}" >/dev/null

mkdir -p "${fixture_repo}/empty-tree-src"
if python3 "${generator}" --repo-root "${fixture_repo}" >/dev/null 2>&1; then
  echo "expected generator to reject empty tree source" >&2
  exit 1
fi
rm -rf "${fixture_repo}/empty-tree-src"

printf 'bad\0tree' > "${fixture_repo}/bad-tree-src"
if python3 "${generator}" --repo-root "${fixture_repo}" >/dev/null 2>&1; then
  echo "expected generator to reject binary tree source" >&2
  exit 1
fi
rm -f "${fixture_repo}/bad-tree-src"

ln -s missing-target "${fixture_repo}/broken-tree-src"
if python3 "${generator}" --repo-root "${fixture_repo}" >/dev/null 2>&1; then
  echo "expected generator to reject single-file symlink tree source" >&2
  exit 1
fi

echo "tree codegen check passed"
