#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -gt 1 ]; then
  echo "usage: $0 [pkgs-attr]" >&2
  exit 1
fi

attr="${1:-test_reports}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$(cd "${repo_root}/.." && pwd)"
pkgs_file="${repo_root}/pkgs.ncl"
recipe_json="${workspace_root}/.mbuild/recipe.json"
mbuild_bin="${workspace_root}/mbuild/target/debug/mbuild"
tree_generator="${repo_root}/tools/generate-tree-modules.py"

mkdir -p "$(dirname "${recipe_json}")"

echo "==> regenerate tree modules" >&2
python3 "${tree_generator}"

expr=$(cat <<EOF_INNER
let pkgs = import "${pkgs_file}" in
pkgs.${attr}
EOF_INNER
)

echo "==> export pkgs.${attr}" >&2
printf '%s\n' "${expr}" | nickel export --format json > "${recipe_json}"

echo "==> build pkgs.${attr}" >&2
(
  cd "${workspace_root}"
  "${mbuild_bin}" build "${recipe_json}"
)
