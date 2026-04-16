#!/usr/bin/env bash
set -euo pipefail

phase="${1:-${MBUILD_STEP_NAME:-}}"
phase="${phase:?step name is required}"
dest="${MBUILD_INSTALL_DIR:?MBUILD_INSTALL_DIR is required}"

if [ "$phase" != "post_install" ]; then
  exit 0
fi

mkdir -p "$dest"

copied=0

for input_dir in /in/sources*; do
  [ -d "$input_dir" ] || continue

  while IFS= read -r -d '' report; do
    cp "$report" "$dest/"
    copied=$((copied + 1))
  done < <(find "$input_dir" -maxdepth 1 -type f -name 'report-*.txt' -print0 | sort -z)
done

printf '%s\n' "$copied" > "$dest/copied-count.txt"
