#!/usr/bin/env bash

# Build a single recipe attribute from mbuild-recipes/request.ncl.
# Regenerates tree modules, exports the target request into
# .mbuild/recipe.json, and then invokes mbuild on that request.

set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "usage: $0 [pkgs-attr]" >&2
  exit 1
fi

attr="${1:-test_reports}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$(cd "${repo_root}/.." && pwd)"
request_file="${repo_root}/request.ncl"
recipe_json="${workspace_root}/.mbuild/recipe.json"
mbuild_bin="${workspace_root}/mbuild/target/debug/mbuild"
tree_generator="${repo_root}/tools/generate-tree-modules.py"

mkdir -p "$(dirname "${recipe_json}")"

echo "==> regenerate tree modules" >&2
python3 "${tree_generator}"

expr=$(cat <<EOF_INNER
let request = import "${request_file}" in
request "${attr}"
EOF_INNER
)

echo "==> export request for ${attr}" >&2
printf '%s\n' "${expr}" | nickel export --format json > "${recipe_json}"

echo "==> build ${attr}" >&2
(
  cd "${workspace_root}"
  "${mbuild_bin}" build "${recipe_json}"
)
