#!/usr/bin/env bash
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
name="$(cat "${cfg}/name")"
dest="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"

if [ -z "$name" ]; then
  echo "test-rootfs: config name must not be empty" >&2
  exit 1
fi

mkdir -p "$dest"

checked=0
failures=0
status="ok"
tmp_report="${dest}/report-${name}.tmp"
have_ldd="yes"

log_check() {
  local msg="$1"
  echo "CHECK ${msg}"
}

log_ok() {
  local msg="$1"
  echo "OK    ${msg}"
}

log_fail() {
  local msg="$1"
  failures=$((failures + 1))
  echo "FAIL  ${msg}"
}

config_flag() {
  local key="$1"
  if [ -f "${cfg}/${key}" ]; then
    case "$(cat "${cfg}/${key}")" in
      true|TRUE|1|yes|YES)
        return 0
        ;;
    esac
  fi
  return 1
}

has_elf_magic() {
  local path="$1"
  local magic
  magic="$(dd if="$path" bs=4 count=1 2>/dev/null | od -An -tx1 -v 2>/dev/null | tr -d ' \n')"
  [ "$magic" = "7f454c46" ]
}

enumerate_paths() {
  local root
  for root in /usr/bin /usr/libexec /usr/lib /usr/lib64 /lib64; do
    [ -e "$root" ] || continue
    find "$root" \( -type f -o -type l \) -print0 2>/dev/null
  done
}

check_broken_symlink() {
  local path="$1"

  if [ -L "$path" ] && [ ! -e "$path" ]; then
    log_fail "broken symlink $path -> $(readlink "$path" 2>/dev/null || echo '?')"
    return 0
  fi

  return 1
}

check_shebang_interpreter() {
  local path="$1"
  local header first_line interpreter rest env_cmd

  header="$(dd if="$path" bs=2 count=1 2>/dev/null || true)"
  [ "$header" = "#!" ] || return 1

  first_line="$({
    head -n 1 "$path" 2>/dev/null \
      | sed -e 's/^#![[:space:]]*//'
  })"
  interpreter="$(printf '%s\n' "$first_line" | sed -e 's/[[:space:]].*$//')"
  [ -n "$interpreter" ] || return 1

  case "$interpreter" in
    /usr/bin/env|/bin/env)
      rest="$(printf '%s\n' "$first_line" | sed -e 's/^[^[:space:]]*[[:space:]]*//')"
      env_cmd="$(printf '%s\n' "$rest" | sed -e 's/[[:space:]].*$//')"
      [ -n "$env_cmd" ] || return 1

      if ! command -v "$env_cmd" >/dev/null 2>&1; then
        log_fail "missing env shebang command for $path (command: $env_cmd)"
        return 0
      fi
      return 1
      ;;
    /*)
      if [ ! -e "$interpreter" ]; then
        log_fail "missing shebang interpreter for $path (interpreter: $interpreter)"
        return 0
      fi
      return 1
      ;;
    *)
      return 1
      ;;
  esac
}

run_python_check() {
  local cmd version import_output

  log_check "python toolchain commands are present"
  for cmd in python3 pip3 meson ninja; do
    if command -v "$cmd" >/dev/null 2>&1; then
      log_ok "command available: $cmd -> $(command -v "$cmd")"
    else
      log_fail "command missing: $cmd"
    fi
  done

  log_check "python toolchain commands execute successfully"
  if version="$(python3 --version 2>&1)"; then
    log_ok "python3 --version"
    echo "INFO  ${version}"
  else
    log_fail "python3 --version failed"
  fi

  if version="$(python3 -m pip --version 2>&1)"; then
    log_ok "python3 -m pip --version"
    echo "INFO  ${version}"
  else
    log_fail "python3 -m pip --version failed"
  fi

  if version="$(meson --version 2>&1)"; then
    log_ok "meson --version"
    echo "INFO  meson ${version}"
  else
    log_fail "meson --version failed"
  fi

  if version="$(ninja --version 2>&1)"; then
    log_ok "ninja --version"
    echo "INFO  ninja ${version}"
  else
    log_fail "ninja --version failed"
  fi

  log_check "python modules import successfully"
  if import_output="$(python3 - <<'EOF_INNER'
import flit_core
import packaging
import wheel
import setuptools
import markupsafe
import jinja2
import mesonbuild

print('IMPORTS_OK')
print('flit_core=' + flit_core.__file__)
print('packaging=' + packaging.__file__)
print('wheel=' + wheel.__file__)
print('setuptools=' + setuptools.__file__)
print('markupsafe=' + markupsafe.__file__)
print('jinja2=' + jinja2.__file__)
print('mesonbuild=' + mesonbuild.__file__)
EOF_INNER
 2>&1)"; then
    if grep -qx 'IMPORTS_OK' <<< "${import_output}"; then
      log_ok "python module imports"
      while IFS= read -r line; do
        echo "INFO  ${line}"
      done <<< "${import_output}"
    else
      log_fail "python module imports did not emit success marker"
      while IFS= read -r line; do
        [ -n "$line" ] && echo "INFO  ${line}"
      done <<< "${import_output}"
    fi
  else
    log_fail "python module imports failed"
    while IFS= read -r line; do
      [ -n "$line" ] && echo "INFO  ${line}"
    done <<< "${import_output}"
  fi
}

if ! command -v ldd >/dev/null 2>&1; then
  status="error"
  have_ldd="no"
fi

{
  echo "test-rootfs report"
  echo "name: ${name}"
  echo "ldd: $(command -v ldd || echo missing)"

  if [ "$have_ldd" = "no" ]; then
    echo
    log_fail "ldd is required for ELF dependency checks"
  fi

  echo
  log_check "filesystem and runtime references"
  if [ -L /sbin ] && [ "$(readlink /sbin)" = "usr/bin" ]; then
    log_ok "/sbin points to /usr/bin"
  else
    log_fail "/sbin is not the expected relative symlink"
  fi

  if [ -L /usr/sbin ] && [ "$(readlink /usr/sbin)" = "bin" ]; then
    log_ok "/usr/sbin points to /usr/bin"
  else
    log_fail "/usr/sbin is not the expected relative symlink"
  fi

  if [ -f /usr/lib/os-release ]; then
    log_ok "/usr/lib/os-release exists"
  else
    log_fail "/usr/lib/os-release is missing"
  fi

  if [ -L /etc/os-release ] && [ "$(readlink /etc/os-release)" = "../usr/lib/os-release" ]; then
    log_ok "/etc/os-release points to /usr/lib/os-release"
  else
    log_fail "/etc/os-release is not the expected relative symlink"
  fi

  if grep -qx 'ID=mbuild' /usr/lib/os-release 2>/dev/null; then
    log_ok "os-release contains ID=mbuild"
  else
    log_fail "os-release does not contain ID=mbuild"
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
        log_fail "$path has unresolved shared libraries"
        while IFS= read -r line; do
          [ -n "$line" ] && echo "INFO  ${line}"
        done <<< "$ldd_out"
        ;;
    esac
  done < <(enumerate_paths)
  log_ok "filesystem scan complete (checked: ${checked})"

  echo
  if config_flag check_python; then
    run_python_check
  else
    echo "INFO  python check disabled"
  fi

  if [ "$failures" -ne 0 ]; then
    status="error"
  fi

  echo
  echo "status: ${status}"
  echo "checked: ${checked}"
  echo "failures: ${failures}"
} > "${tmp_report}"

mv "${tmp_report}" "${dest}/report-${name}-${status}.txt"
