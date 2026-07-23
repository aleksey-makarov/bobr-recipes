#!/usr/bin/env bash
# Runtime-closure check for one materialized rootfs, run from OUTSIDE it.
#
# The rootfs to check is mounted read-only at $BOBR_INPUTS_DIR/_target (a
# materialized fs-tree, carrying real modes/symlinks). This script runs in a
# tool-rich OCI rootfs (`_rootfs`), so it needs nothing from the checked tree --
# unlike an in-rootfs scan, it works on minimal rootfs (e.g. the initramfs).
#
# For every ELF under the tree it reads the program interpreter and DT_NEEDED
# via `readelf` (static; never executes the target) and verifies each resolves
# within the tree's OWN library dirs: the standard dirs, the dirs listed in the
# tree's /etc/ld.so.conf(.d) (multiarch layouts live there), and RUNPATH/RPATH
# ($ORIGIN expanded, RUNPATH over RPATH). Scanning every ELF -- including the .so
# libraries themselves -- makes the NEEDED closure transitive. It also flags
# broken symlinks; symlinks whose link or target lives in runtime state
# (/dev,/proc,/sys,/run,/var,/tmp) are legitimately dangling at build time and
# skipped. A missing interpreter / NEEDED / symlink target means the rootfs
# closure is incomplete -- typically a forgotten `deps.runtime`.
#
# Known, per-rootfs-approved failures (private-prefix libs resolved only via the
# loading binary's RUNPATH or a build-time LD_LIBRARY_PATH -- which a static scan
# cannot model) are listed as substring patterns under $BOBR_CONFIG_DIR/suppress.
# A matching failure is reported as INFO, not an error; ANY other failure still
# fails the rootfs, so a new problem on an allowlisted rootfs is never hidden.
#
# Writes report-<name>-<status>.txt to $BOBR_OUT_DIR and always exits 0; the
# gate decides overall pass/fail from the collected reports.
set -euo pipefail

cfg="${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}"
target="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}/_target"
dest="${BOBR_OUT_DIR:?BOBR_OUT_DIR is required}"
name="$(cat "${cfg}/name")"
mkdir -p "$dest"

if [ ! -d "$target" ]; then
  echo "check-rootfs: target tree missing at ${target}" >&2
  exit 1
fi

# Fail loudly if the tool rootfs lacks readelf: without it the scan would find
# no NEEDED and silently report every rootfs as clean (false green).
command -v readelf >/dev/null 2>&1 || {
  echo "check-rootfs: readelf not found in the tool rootfs" >&2
  exit 1
}

default_libdirs=(/lib /lib64 /usr/lib /usr/lib64)
runtime_prefixes=(/dev /proc /sys /run /var /tmp)

# Extra library dirs from the target's own /etc/ld.so.conf(.d) -- this is what
# the real loader searches via ld.so.cache; multiarch trees (e.g. Debian's
# /usr/lib/x86_64-linux-gnu) put libc itself there.
conf_libdirs=()
read_ld_conf() {
  local f="$1" line
  [ -f "$f" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%%#*}"
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    [ -n "$line" ] || continue
    case "$line" in
      include*) ;; # conf.d globs are read directly below
      /*) conf_libdirs+=("$line") ;;
    esac
  done < "$f"
}
read_ld_conf "${target}/etc/ld.so.conf"
if [ -d "${target}/etc/ld.so.conf.d" ]; then
  for c in "${target}"/etc/ld.so.conf.d/*.conf; do
    [ -e "$c" ] && read_ld_conf "$c"
  done
fi

# Approved-failure substrings for this rootfs (see header).
suppress_pats=()
if [ -d "${cfg}/suppress" ]; then
  while IFS= read -r -d '' sf; do
    suppress_pats+=("$(cat "$sf")")
  done < <(find "${cfg}/suppress" -maxdepth 1 -type f -print0)
fi

is_elf() {
  [ "$(dd if="$1" bs=4 count=1 2>/dev/null | od -An -tx1 -v 2>/dev/null | tr -d ' \n')" = "7f454c46" ]
}

# Does a DT_NEEDED name resolve within the target tree?
lib_exists() {
  local libname="$1"
  shift
  local searchdirs=("$@") # target-absolute dirs; $ORIGIN already expanded
  local d
  if [[ "$libname" == */* ]]; then
    [ -e "${target}/${libname#/}" ]
    return
  fi
  for d in "${searchdirs[@]}" "${default_libdirs[@]}" ${conf_libdirs[@]+"${conf_libdirs[@]}"}; do
    [ -e "${target}${d}/${libname}" ] && return 0
  done
  return 1
}

fails=()
infos=()

# Helpers for sourced special_* scripts (and this script) to record findings and
# read script_config flags.
add_fail() { fails+=("$1"); }
add_info() { infos+=("$1"); }
config_flag() {
  local key="$1"
  [ -f "${cfg}/${key}" ] || return 1
  case "$(cat "${cfg}/${key}")" in
    true | TRUE | 1 | yes | YES) return 0 ;;
  esac
  return 1
}

elf_checked=0
while IFS= read -r -d '' f; do
  is_elf "$f" || continue
  rel="/${f#"${target}/"}"
  dyn="$(readelf -d "$f" 2>/dev/null || true)"
  ph="$(readelf -l "$f" 2>/dev/null || true)"

  interp="$(printf '%s\n' "$ph" | sed -n 's/.*Requesting program interpreter: \([^]]*\)\].*/\1/p' | head -n1)"
  needed="$(printf '%s\n' "$dyn" | sed -n 's/.*(NEEDED).*\[\([^]]*\)\].*/\1/p')"
  rpath="$(printf '%s\n' "$dyn" | sed -n 's/.*(RPATH).*\[\([^]]*\)\].*/\1/p' | head -n1)"
  runpath="$(printf '%s\n' "$dyn" | sed -n 's/.*(RUNPATH).*\[\([^]]*\)\].*/\1/p' | head -n1)"

  [ -n "$needed" ] || [ -n "$interp" ] || [ -n "${rpath}${runpath}" ] || continue
  elf_checked=$((elf_checked + 1))

  if [ -n "$interp" ] && [ ! -e "${target}/${interp#/}" ]; then
    fails+=("missing ELF interpreter for ${rel}: ${interp}")
  fi

  configured="${runpath:-$rpath}"
  elfdir="$(dirname "$rel")"
  searchdirs=()
  if [ -n "$configured" ]; then
    IFS=':' read -ra parts <<< "$configured"
    for p in "${parts[@]}"; do
      [ -n "$p" ] || continue
      p="${p//\$\{ORIGIN\}/$elfdir}"
      p="${p//\$ORIGIN/$elfdir}"
      searchdirs+=("$p")
    done
  fi

  while IFS= read -r lib; do
    [ -n "$lib" ] || continue
    lib_exists "$lib" ${searchdirs[@]+"${searchdirs[@]}"} \
      || fails+=("missing shared library for ${rel}: ${lib}")
  done <<< "$needed"
done < <(find "$target" -type f -print0)

sym_checked=0
while IFS= read -r -d '' l; do
  sym_checked=$((sym_checked + 1))
  linkrel="/${l#"${target}/"}"
  t="$(readlink "$l")"
  skip=0
  for pre in "${runtime_prefixes[@]}"; do
    if [ "$linkrel" = "$pre" ] || [[ "$linkrel" == "${pre}/"* ]] \
      || [ "$t" = "$pre" ] || [[ "$t" == "${pre}/"* ]]; then
      skip=1
      break
    fi
  done
  [ "$skip" -eq 1 ] && continue
  if [[ "$t" == /* ]]; then
    resolved="${target}/${t#/}"
  else
    resolved="$(dirname "$l")/${t}"
  fi
  [ -e "$resolved" ] || fails+=("broken symlink ${linkrel} -> ${t}")
done < <(find "$target" -type l -print0)

# Additive per-image checks: every `special_*` script input is sourced here. It
# runs in this script's context ($target, $cfg, add_fail/add_info/config_flag,
# lib_exists, ...) and appends to fails/infos. Ordinary build-rootfs checks pass
# no special_* input, so this is a no-op for them.
for special in "${BOBR_INPUTS_DIR}"/special_*; do
  [ -f "$special" ] || continue
  # shellcheck disable=SC1090
  . "$special"
done

# Split failures into real vs. per-rootfs-approved (suppressed).
is_suppressed() {
  local line="$1" pat
  for pat in ${suppress_pats[@]+"${suppress_pats[@]}"}; do
    [[ "$line" == *"$pat"* ]] && return 0
  done
  return 1
}
real_fails=()
supp_fails=()
for m in ${fails[@]+"${fails[@]}"}; do
  if is_suppressed "$m"; then
    supp_fails+=("$m")
  else
    real_fails+=("$m")
  fi
done

status="ok"
[ "${#real_fails[@]}" -ne 0 ] && status="error"

{
  echo "runtime-rootfs check"
  echo "name: ${name}"
  echo "elf checked: ${elf_checked}"
  echo "symlinks checked: ${sym_checked}"
  echo "suppressed: ${#supp_fails[@]}"
  echo "infos: ${#infos[@]}"
  for m in ${infos[@]+"${infos[@]}"}; do
    echo "INFO  ${m}"
  done
  for m in ${supp_fails[@]+"${supp_fails[@]}"}; do
    echo "INFO  approved: ${m}"
  done
  for m in ${real_fails[@]+"${real_fails[@]}"}; do
    echo "FAIL  ${m}"
  done
  echo "status: ${status}"
  echo "failures: ${#real_fails[@]}"
} > "${dest}/report-${name}-${status}.txt"
