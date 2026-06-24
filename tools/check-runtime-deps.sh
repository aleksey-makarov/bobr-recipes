#!/usr/bin/env bash

# Build a temporary RootfsClosure for one package attribute and check that the
# resulting runtime filesystem has resolvable symlinks and ELF dependencies.

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <pkgs-attr>" >&2
  exit 2
fi

attr="$1"
if [[ ! "${attr}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  echo "invalid pkgs attribute name: ${attr}" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${repo_root}/env.sh"
mbuild_bin="${workspace_root}/mbuild/target/debug/mbuild"
checker="${repo_root}/tools/check-runtime-rootfs.py"
closure_name="${attr}-rootfs-closure"

if [ ! -x "${mbuild_bin}" ]; then
  echo "missing mbuild binary: ${mbuild_bin}" >&2
  exit 2
fi

request_expr="$(mktemp)"
cleanup() {
  rm -f "${request_expr}"
}
trap cleanup EXIT

mkdir -p "${store_root}"

cat > "${request_expr}" <<EOF_INNER
let recipe = import "${repo_root}/recipe-lib.ncl" in
let pkgs = (import "${repo_root}/pkgs.ncl") [] in
{
  schema = "bobr-request-v1",
  store = "${store_root}",
  nodes = recipe.to_request { recipes_path = "${recipes_root}" } pkgs {
    name = "${closure_name}",
    tag = "RootfsClosure",
    config = {},
    inputs = {
      root = std.record.get "${attr}" pkgs,
    },
  },
}
EOF_INNER

echo "==> export runtime rootfs request for ${attr}" >&2
echo "==> build ${closure_name}" >&2
(
  cd "${workspace_root}"
  nickel export "${request_expr}" --format json | "${mbuild_bin}"
)

rootfs_root="${store_root}/object-refs/${closure_name}/root"
echo "==> check runtime rootfs ${closure_name}" >&2
python3 "${checker}" --root "${rootfs_root}" --name "${closure_name}"
