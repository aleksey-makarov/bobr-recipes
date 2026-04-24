#!/usr/bin/env bash

# Build a single recipe attribute through `request.ncl(store_path, target_name)`.
# Regenerates tree modules, exports the full JSON request envelope, and pipes
# it directly into `mbuild`. Store configuration comes from `mbuild-recipes/env.sh`.

set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "usage: $0 [pkgs-attr]" >&2
  exit 1
fi

attr="${1:-test_reports}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${repo_root}/env.sh"
request_file="${repo_root}/request.ncl"
mbuild_bin="${workspace_root}/mbuild/target/debug/mbuild"
tree_generator="${repo_root}/tools/generate-tree-modules.py"

mkdir -p "${store_root}"

echo "==> regenerate tree modules" >&2
python3 "${tree_generator}"

expr=$(cat <<EOF_INNER
let request = import "${request_file}" in
request "${store_root}" "${attr}"
EOF_INNER
)

echo "==> export request for ${attr}" >&2
echo "==> build ${attr}" >&2
(
  cd "${workspace_root}"
  printf '%s\n' "${expr}" | nickel export --format json | "${mbuild_bin}"
)
