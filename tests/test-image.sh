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
have_ldd="yes"

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

check_broken_symlink() {
  local path="$1"

  if [ -L "$path" ] && [ ! -e "$path" ]; then
    failures=$((failures + 1))
    echo
    echo "FAIL broken symlink $path -> $(readlink "$path" 2>/dev/null || echo '?')"
    return 0
  fi

  return 1
}

check_shebang_interpreter() {
  local path="$1"
  local header interpreter

  header="$(dd if="$path" bs=2 count=1 2>/dev/null || true)"
  [ "$header" = "#!" ] || return 1

  interpreter="$(
    head -n 1 "$path" 2>/dev/null \
      | sed -e 's/^#![[:space:]]*//' -e 's/[[:space:]].*$//'
  )"
  [ -n "$interpreter" ] || return 1

  if [ ! -e "$interpreter" ]; then
    failures=$((failures + 1))
    echo
    echo "FAIL missing shebang interpreter for $path"
    echo "interpreter: $interpreter"
    return 0
  fi

  return 1
}

if ! command -v ldd >/dev/null 2>&1; then
  status="error"
  have_ldd="no"
fi

{
  echo "test-image report"
  echo "name: ${name}"
  echo "kernel: $(uname -srmo)"
  echo "ldd: $(command -v ldd || echo missing)"

  if [ "$have_ldd" = "no" ]; then
    echo
    echo "error: ldd is required for ELF dependency checks"
  fi

  while IFS= read -r -d '' path; do
    checked=$((checked + 1))

    if check_broken_symlink "$path"; then
      continue
    fi

    [ -f "$path" ] || continue

    if check_shebang_interpreter "$path"; then
      continue
    fi

    if [ "$have_ldd" = "no" ]; then
      continue
    fi

    has_elf_magic "$path" || continue

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

  echo
  echo "status: ${status}"
  echo "checked: ${checked}"
  echo "failures: ${failures}"
} > "${tmp_report}"

mv "${tmp_report}" "${dest}/report-${name}-${status}.txt"
