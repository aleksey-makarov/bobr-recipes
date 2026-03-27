#!/usr/bin/env bash
set -euo pipefail

out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
cfg="${MBUILD_SCRIPT_CONFIG_DIR:?MBUILD_SCRIPT_CONFIG_DIR is required}"
name="$(cat "${cfg}/name")"
dest="/out/${out}"

if [ -z "$name" ]; then
  echo "test-image: config name must not be empty" >&2
  exit 1
fi

mkdir -p "$dest"

checked=0
failures=0
status="ok"
tmp_report="${dest}/report-${name}.tmp"

has_elf_magic() {
  local path="$1"
  local magic
  magic="$(dd if="$path" bs=4 count=1 2>/dev/null | od -An -tx1 -v 2>/dev/null | tr -d ' \n')"
  [ "$magic" = "7f454c46" ]
}

enumerate_paths() {
  local root
  for root in /usr/bin /usr/sbin /usr/libexec /usr/lib /usr/lib64 /lib64; do
    [ -e "$root" ] || continue
    find "$root" \( -type f -o -type l \) -print0 2>/dev/null
  done
}

if ! command -v ldd >/dev/null 2>&1; then
  status="error"
fi

{
  echo "test-image report"
  echo "name: ${name}"
  echo "kernel: $(uname -srmo)"
  echo "ldd: $(command -v ldd || echo missing)"

  if [ "$status" = "error" ]; then
    echo
    echo "error: ldd is required"
  else
    while IFS= read -r -d '' path; do
      [ -f "$path" ] || continue
      [ -L "$path" ] && continue
      has_elf_magic "$path" || continue

      checked=$((checked + 1))

      ldd_out=""
      if ! ldd_out="$(ldd "$path" 2>&1)"; then
        :
      fi

      case "$ldd_out" in
        *"not found"*|*"error while loading shared libraries:"*)
          failures=$((failures + 1))
          echo
          echo "FAIL $path"
          echo "$ldd_out"
          ;;
      esac
    done < <(enumerate_paths)

    if [ "$failures" -ne 0 ]; then
      status="error"
    fi
  fi

  echo
  echo "status: ${status}"
  echo "checked: ${checked}"
  echo "failures: ${failures}"
} > "${tmp_report}"

mv "${tmp_report}" "${dest}/report-${name}-${status}.txt"
