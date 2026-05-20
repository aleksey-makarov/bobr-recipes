#!/usr/bin/env bash

# Smoke-test the synthetic TreeSubset helper on a small mounted tree root.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
helper="${repo_root}/synthetic/tree-subset.py"
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

root="${tmpdir}/input-root"
config="${tmpdir}/config"
out="${tmpdir}/out"

mkdir -p "${root}/usr/lib64" "${root}/usr/bin" "${config}/include" "${out}"
printf 'runtime\n' > "${root}/usr/lib64/libfoo.so.1"
printf 'tool\n' > "${root}/usr/bin/tool"
ln -s libfoo.so.1 "${root}/usr/lib64/libfoo.so"
chmod 0755 "${root}/usr/lib64/libfoo.so.1"
chmod 0755 "${root}/usr/bin/tool"

printf '%s' 'usr/lib64/libfoo.so*' > "${config}/include/00000000"

python3 "${helper}" --input "${root}" --output "${out}" --config "${config}"

test -d "${out}/usr"
test -d "${out}/usr/lib64"
test -f "${out}/usr/lib64/libfoo.so.1"
test -L "${out}/usr/lib64/libfoo.so"
test "$(readlink "${out}/usr/lib64/libfoo.so")" = "libfoo.so.1"
test ! -e "${out}/usr/bin/tool"

if python3 "${helper}" --input "${root}" --output "${tmpdir}/missing-out" --config "${tmpdir}/missing-config" >/dev/null 2>&1; then
  echo "expected missing include config failure" >&2
  exit 1
fi

mkdir -p "${tmpdir}/nomatch-config/include" "${tmpdir}/nomatch-out"
printf '%s' 'usr/lib64/libmissing.so*' > "${tmpdir}/nomatch-config/include/00000000"
if python3 "${helper}" --input "${root}" --output "${tmpdir}/nomatch-out" --config "${tmpdir}/nomatch-config" >/dev/null 2>&1; then
  echo "expected no-match include failure" >&2
  exit 1
fi

echo "tree-subset helper smoke tests passed"
