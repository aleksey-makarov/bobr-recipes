#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <pkgs-attr>" >&2
  exit 1
fi

attr="$1"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$(cd "${repo_root}/.." && pwd)"
pkgs_file="${repo_root}/pkgs.ncl"
recipe_json="${workspace_root}/.mbuild/recipe.json"
mbuild_bin="${workspace_root}/mbuild/target/debug/mbuild"

mkdir -p "$(dirname "${recipe_json}")"

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
