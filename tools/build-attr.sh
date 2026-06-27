#!/usr/bin/env bash

# Build a single recipe attribute through `request.ncl({ ... })`.
# Regenerates tree modules, exports the full JSON request envelope, and pipes
# it directly into `bobr`. Store and recipe source configuration come from
# `bobr-recipes/env.sh`.

set -euo pipefail

usage() {
  echo "usage: $0 [--jobs N] [pkgs-attr]" >&2
}

jobs=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --jobs|-j)
      if [ "$#" -lt 2 ]; then
        usage
        exit 2
      fi
      jobs="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --*)
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [ "$#" -gt 1 ]; then
  usage
  exit 2
fi

if [ -n "${jobs}" ] && ! [[ "${jobs}" =~ ^[1-9][0-9]*$ ]]; then
  echo "build-attr.sh: --jobs must be a positive integer" >&2
  exit 2
fi

attr="${1:-all_test_artifacts}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${repo_root}/env.sh"
request_file="${repo_root}/request.ncl"
bobr_bin="${workspace_root}/bobr/target/debug/bobr"
tree_generator="${repo_root}/tools/generate-tree-modules.py"
overlays_file="$(pwd)/bobr-overlays.ncl"
overlays_expr="[]"

if [ -f "${overlays_file}" ]; then
  overlays_expr="import \"${overlays_file}\""
fi

mkdir -p "${store_root}"

echo "==> regenerate tree modules" >&2
python3 "${tree_generator}"

if [ -n "${jobs}" ]; then
  expr=$(cat <<EOF_INNER
let request = import "${request_file}" in
let base = request {
  store_path = "${store_root}",
  recipes_path = "${recipes_root}",
  target_name = "${attr}",
  overlays = ${overlays_expr},
} in
base & {
  jobs = ${jobs},
}
EOF_INNER
  )
else
  expr=$(cat <<EOF_INNER
let request = import "${request_file}" in
request {
  store_path = "${store_root}",
  recipes_path = "${recipes_root}",
  target_name = "${attr}",
  overlays = ${overlays_expr},
}
EOF_INNER
  )
fi

echo "==> export request for ${attr}" >&2
if [ -n "${jobs}" ]; then
  echo "==> use jobs=${jobs}" >&2
fi
echo "==> build ${attr}" >&2
(
  cd "${workspace_root}"
  TIMEFORMAT="==> pipeline time: real %R s, user %U s, sys %S s"
  time (printf '%s\n' "${expr}" | nickel export --format json | "${bobr_bin}")
)
