#!/usr/bin/env bash
set -euo pipefail

dest="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"

mkdir -p "$dest"

copied=0

copy_reports_from_dir() {
  local report_dir="$1"

  [ -d "$report_dir" ] || return 0

  while IFS= read -r -d '' report; do
    cp "$report" "$dest/"
    copied=$((copied + 1))
  done < <(find "$report_dir" -maxdepth 1 -type f -name 'report-*.txt' -print0 | sort -z)
}

for input_dir in "$BOBR_INPUTS_DIR"/report*; do
  [ -d "$input_dir" ] || continue

  copy_reports_from_dir "$input_dir"
done

printf '%s\n' "$copied" > "$dest/copied-count.txt"
