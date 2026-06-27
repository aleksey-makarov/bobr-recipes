#!/usr/bin/env bash

# Export one `bobr` JSON request for a single package attribute.
#
# This is the safe inspection path for `pkgs.ncl`: it selects one target through
# `request.ncl` and never serializes the complete fixed-point package set.

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") [--store PATH] [--recipes PATH] <pkgs-attr>" >&2
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
request_file="${repo_root}/request.ncl"
store_path="/tmp/bobr-store"
recipes_path="${repo_root}"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --store)
      if [ "$#" -lt 2 ]; then
        usage
        exit 2
      fi
      store_path="$2"
      shift 2
      ;;
    --recipes)
      if [ "$#" -lt 2 ]; then
        usage
        exit 2
      fi
      recipes_path="$2"
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

if [ "$#" -ne 1 ]; then
  usage
  exit 2
fi

attr="$1"

if [[ "${store_path}" != /* ]]; then
  echo "export-request.sh: --store must be an absolute path" >&2
  exit 2
fi

if [[ "${recipes_path}" != /* ]]; then
  echo "export-request.sh: --recipes must be an absolute path" >&2
  exit 2
fi

expr=$(cat <<EOF_INNER
let request = import "${request_file}" in
request {
  store_path = "${store_path}",
  recipes_path = "${recipes_path}",
  target_name = "${attr}",
}
EOF_INNER
)

printf '%s\n' "${expr}" | nickel export --format json
