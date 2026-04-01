#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$(cd "${repo_root}/.." && pwd)"
mbuild_bin="${workspace_root}/mbuild/target/debug/mbuild"
recipe_json="${workspace_root}/.mbuild/recipe.json"

if [ "$#" -eq 0 ]; then
  targets=(test-reports)
else
  targets=("$@")
fi

mkdir -p "$(dirname "${recipe_json}")"

for target in "${targets[@]}"; do
  echo "==> export ${target}" >&2
  nickel export "${repo_root}/targets/${target}.ncl" --format json > "${recipe_json}"
  echo "==> build ${target}" >&2
  (
    cd "${workspace_root}"
    "${mbuild_bin}" build "${recipe_json}"
  )
done
