#!/usr/bin/env bash
# Rootfs-check gate: read the bundled per-rootfs reports and FAIL the build if
# any rootfs check reported errors. The reports arrive as one `Bundle` input
# (`reports/`) -- one file per checked rootfs, named by the checker node -- so
# this node bind-mounts a single object rather than one per rootfs. Unlike
# test-reports.sh (which only collects), this is a CI gate: a non-zero exit
# stops `bobr build check_all_rootfs`.
#
# Bundle names each entry by the input node name, so the `-ok`/`-error` status
# is no longer in the file name; detect it from the report body instead (each
# report carries a `status:` line written by test-rootfs.sh).
set -euo pipefail

dest="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"
inputs="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}"
bundle="${inputs}/reports"
mkdir -p "$dest"

if [ ! -d "$bundle" ]; then
  echo "check_all_rootfs: reports bundle input is missing" >&2
  exit 1
fi

copied=0
errors=0
while IFS= read -r -d '' report; do
  base="$(basename "$report")"
  cp "$report" "$dest/report-${base}.txt"
  copied=$((copied + 1))
  if grep -qx 'status: error' "$report"; then
    errors=$((errors + 1))
    echo "ROOTFS CHECK FAILED: ${base}" >&2
    sed 's/^/  | /' "$report" >&2
  fi
done < <(find "$bundle" -maxdepth 1 -type f -print0 | sort -z)

printf '%s\n' "$copied" > "$dest/copied-count.txt"
printf '%s\n' "$errors" > "$dest/error-count.txt"

echo "check_all_rootfs: collected ${copied} report(s), ${errors} with errors" >&2
if [ "$errors" -ne 0 ]; then
  echo "check_all_rootfs: FAILED (${errors} rootfs check(s) reported errors)" >&2
  exit 1
fi
echo "check_all_rootfs: OK" >&2
