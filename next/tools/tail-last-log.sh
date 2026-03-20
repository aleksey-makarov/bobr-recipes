#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: tail-last-log.sh <target-name> [builder]

Tail the newest raw builder log for one published target.

Examples:
  tail-last-log.sh gcc-temp-15.2.0
  tail-last-log.sh glibc-temp-2.42 binary
  MBUILD_WORKSPACE=/path/to/workspace tail-last-log.sh gcc-temp-build-image image
EOF
  exit 2
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
fi

target_name="$1"
builder="${2:-binary}"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
workspace_root="${MBUILD_WORKSPACE:-$(cd "${script_dir}/../../.." && pwd)}"
log_dir="${workspace_root}/.mbuild/builder-state/${builder}/logs/${target_name}"

if [ ! -d "${log_dir}" ]; then
  echo "error: log directory does not exist: ${log_dir}" >&2
  exit 1
fi

latest_log="$(
  find "${log_dir}" -maxdepth 1 -type f -name '*.log' -printf '%T@ %p\n' \
    | sort -nr \
    | head -n1 \
    | cut -d' ' -f2-
)"

if [ -z "${latest_log}" ]; then
  echo "error: no log files found in ${log_dir}" >&2
  exit 1
fi

echo "tailing ${latest_log}" >&2
exec tail -f "${latest_log}"
