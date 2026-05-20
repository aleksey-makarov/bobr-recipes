#!/usr/bin/env bash

# Export one `mbuild` JSON request for a single package attribute.
#
# This is the safe inspection path for `pkgs.ncl`: it selects one target through
# `request.ncl` and never serializes the complete fixed-point package set.

set -euo pipefail

usage() {
  echo "usage: $(basename "$0") [--store PATH] [--local PATH] <pkgs-attr>" >&2
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
request_file="${repo_root}/request.ncl"
store_path="/tmp/mbuild-store"
local_path=""

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
    --local)
      if [ "$#" -lt 2 ]; then
        usage
        exit 2
      fi
      local_path="$2"
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

if [ -n "${local_path}" ] && [[ "${local_path}" != /* ]]; then
  echo "export-request.sh: --local must be an absolute path" >&2
  exit 2
fi

if [ -n "${local_path}" ]; then
  expr=$(cat <<EOF_INNER
let request = import "${request_file}" in
request {
  store_path = "${store_path}",
  local_path = "${local_path}",
  target_name = "${attr}",
}
EOF_INNER
)
else
  expr=$(cat <<EOF_INNER
let request = import "${request_file}" in
request {
  store_path = "${store_path}",
  target_name = "${attr}",
}
EOF_INNER
)
fi

printf '%s\n' "${expr}" | nickel export --format json
