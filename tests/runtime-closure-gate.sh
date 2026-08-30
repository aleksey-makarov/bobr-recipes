#!/usr/bin/env bash
# Convert an already-published runtime closure audit status into goal success or
# failure. The substantive report is an input object, so a failing gate cannot
# lose it through cancellation or failed-output cleanup.
set -euo pipefail

audit="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}/audit"
dest="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"

if [ ! -d "$audit" ] || [ ! -f "${audit}/status" ] \
  || [ ! -f "${audit}/summary.txt" ]; then
  echo "runtime-closure-gate: incomplete audit input" >&2
  exit 1
fi

status="$(cat "${audit}/status")"
case "$status" in
  ok)
    mkdir -p "$dest"
    cp "${audit}/status" "${dest}/status"
    cp "${audit}/summary.txt" "${dest}/summary.txt"
    ;;
  error)
    cat "${audit}/summary.txt" >&2
    exit 1
    ;;
  *)
    echo "runtime-closure-gate: invalid audit status '${status}'" >&2
    exit 1
    ;;
esac
