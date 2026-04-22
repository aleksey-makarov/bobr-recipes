#!/usr/bin/env bash
set -euo pipefail

dest="${MBUILD_OUT_DIR:?MBUILD_OUT_DIR is required}"

mkdir -p "$dest"

copied=0

for input_dir in /__mbuild/inputs/report*; do
  [ -d "$input_dir" ] || continue

  while IFS= read -r -d '' report; do
    cp "$report" "$dest/"
    copied=$((copied + 1))
  done < <(find "$input_dir" -maxdepth 1 -type f -name 'report-*.txt' -print0 | sort -z)
done

printf '%s\n' "$copied" > "$dest/copied-count.txt"
