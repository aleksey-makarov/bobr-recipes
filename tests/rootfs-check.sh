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
# Package runtime checks additionally mount the package output as `_subject`
# and every direct deps.runtime entry as a numbered private input. Static
# references from the subject are attributed to those providers and recorded
# as raw observed/unobserved/redundant findings. Policy is applied only later
# by the aggregate runtime-closure audit.
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
inputs="${BOBR_INPUTS_DIR:?BOBR_INPUTS_DIR is required}"
target="${inputs}/_target"
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

default_libdirs=(/lib /lib64 /usr/lib)
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

# Resolve a DT_NEEDED name within the target tree and print its target-absolute
# pathname. Keeping the pathname lets the dependency audit attribute a static
# reference from the package output to a direct deps.runtime provider.
resolve_lib_path() {
  local libname="$1"
  shift
  local searchdirs=("$@") # target-absolute dirs; $ORIGIN already expanded
  local d candidate
  if [[ "$libname" == */* ]]; then
    candidate="/${libname#/}"
    if [ -e "${target}${candidate}" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    return 1
  fi
  for d in "${searchdirs[@]}" "${default_libdirs[@]}" ${conf_libdirs[@]+"${conf_libdirs[@]}"}; do
    candidate="$(realpath -m -s -- "${d}/${libname}")"
    case "$candidate" in
      /*) ;;
      *) candidate="/${candidate}" ;;
    esac
    if [ -e "${target}${candidate}" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

lib_exists() {
  resolve_lib_path "$@" >/dev/null
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

# For package runtime-closure checks, attribute static references from the
# package's own output (`_subject`) to its direct deps.runtime inputs
# (`_runtime_dep_nNNN`).
# This is intentionally evidence, not policy: dependencies used through
# dlopen, exec, plugins, or data files remain `unobserved` here and are handled
# by the aggregate audit's explicit allowlist.
runtime_dep_total=0
runtime_dep_observed=0
runtime_dep_unobserved=0
runtime_dep_redundant=0
runtime_dep_lines=()
if [ -e "${inputs}/_subject" ]; then
  subject="${inputs}/_subject"
  subject_name="$(cat "${cfg}/subject")"
  if [ ! -d "$subject" ]; then
    echo "check-rootfs: subject is not a directory tree: ${subject}" >&2
    exit 1
  fi

  runtime_dep_slots=()
  declare -A runtime_dep_names=()
  declare -A runtime_dep_seen=()
  declare -A runtime_dep_evidence=()
  declare -A runtime_dep_redundant_via=()

  if [ -d "${cfg}/runtime_dependencies" ]; then
    while IFS= read -r -d '' dep_cfg; do
      slot="$(basename "$dep_cfg")"
      dep_name="$(cat "$dep_cfg")"
      if [ -z "$dep_name" ]; then
        echo "check-rootfs: empty runtime dependency name for ${slot}" >&2
        exit 1
      fi
      if [ ! -d "${inputs}/${slot}" ]; then
        echo "check-rootfs: runtime dependency ${slot} is not a directory tree" >&2
        exit 1
      fi
      runtime_dep_slots+=("$slot")
      runtime_dep_names["$slot"]="$dep_name"
      runtime_dep_seen["$slot"]=0
      runtime_dep_evidence["$slot"]=""
      redundant_cfg="${cfg}/redundant_runtime_dependencies/${slot}"
      runtime_dep_redundant_via["$slot"]=""
      if [ -f "$redundant_cfg" ]; then
        runtime_dep_redundant_via["$slot"]="$(cat "$redundant_cfg")"
      fi
    done < <(find "${cfg}/runtime_dependencies" -maxdepth 1 -type f -print0 | sort -z)
  fi

  canonical_target_path() {
    local logical="$1" resolved
    resolved="$(realpath -m -- "${target}/${logical#/}")"
    case "$resolved" in
      "${target}") printf '/\n' ;;
      "${target}/"*) printf '/%s\n' "${resolved#"${target}/"}" ;;
      *) return 1 ;;
    esac
  }

  mark_runtime_provider() {
    local logical="$1" evidence="$2" canonical slot candidate
    canonical="$(canonical_target_path "$logical" 2>/dev/null || true)"
    for slot in ${runtime_dep_slots[@]+"${runtime_dep_slots[@]}"}; do
      for candidate in "$logical" "$canonical"; do
        [ -n "$candidate" ] || continue
        if [ -e "${inputs}/${slot}${candidate}" ] \
          || [ -L "${inputs}/${slot}${candidate}" ]; then
          runtime_dep_seen["$slot"]=1
          if [ -z "${runtime_dep_evidence[$slot]}" ]; then
            runtime_dep_evidence["$slot"]="${evidence}:${logical}"
          fi
          break
        fi
      done
    done
  }

  while IFS= read -r -d '' f; do
    is_elf "$f" || continue
    rel="/${f#"${subject}/"}"
    dyn="$(readelf -d "$f" 2>/dev/null || true)"
    ph="$(readelf -l "$f" 2>/dev/null || true)"
    interp="$(printf '%s\n' "$ph" | sed -n 's/.*Requesting program interpreter: \([^]]*\)\].*/\1/p' | head -n1)"
    needed="$(printf '%s\n' "$dyn" | sed -n 's/.*(NEEDED).*\[\([^]]*\)\].*/\1/p')"
    rpath="$(printf '%s\n' "$dyn" | sed -n 's/.*(RPATH).*\[\([^]]*\)\].*/\1/p' | head -n1)"
    runpath="$(printf '%s\n' "$dyn" | sed -n 's/.*(RUNPATH).*\[\([^]]*\)\].*/\1/p' | head -n1)"

    if [ -n "$interp" ] && [ -e "${target}/${interp#/}" ]; then
      mark_runtime_provider "$interp" "elf-interpreter:${rel}"
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
      resolved="$(resolve_lib_path "$lib" ${searchdirs[@]+"${searchdirs[@]}"} || true)"
      [ -n "$resolved" ] \
        && mark_runtime_provider "$resolved" "elf-needed:${rel}:${lib}"
    done <<< "$needed"
  done < <(find "$subject" -type f -print0 | sort -z)

  # Absolute and relative symlinks in the package output can refer to files
  # supplied by another package even when no ELF metadata mentions them.
  while IFS= read -r -d '' l; do
    linkrel="/${l#"${subject}/"}"
    link_target="$(readlink "$l")"
    if [[ "$link_target" == /* ]]; then
      resolved="$link_target"
    else
      resolved="$(realpath -m -s -- "$(dirname "$linkrel")/${link_target}")"
    fi
    [ -e "${target}/${resolved#/}" ] \
      && mark_runtime_provider "$resolved" "symlink:${linkrel}"
  done < <(find "$subject" -type l -print0 | sort -z)

  # A shebang is another explicit static runtime reference. Handle ordinary
  # absolute interpreters and the common `/usr/bin/env command` form.
  while IFS= read -r -d '' f; do
    [ "$(dd if="$f" bs=2 count=1 2>/dev/null || true)" = '#!' ] || continue
    first="$(sed -n '1{s/^#![[:space:]]*//;p;q}' "$f" 2>/dev/null || true)"
    interpreter="${first%%[[:space:]]*}"
    [ -n "$interpreter" ] || continue
    rel="/${f#"${subject}/"}"
    case "$interpreter" in
      /usr/bin/env | /bin/env)
        mark_runtime_provider "$interpreter" "shebang:${rel}"
        rest="${first#"$interpreter"}"
        rest="${rest#"${rest%%[![:space:]]*}"}"
        command_name="${rest%%[[:space:]]*}"
        [ -n "$command_name" ] || continue
        if [[ "$command_name" == /* ]]; then
          command_path="$command_name"
        elif [ -e "${target}/usr/bin/${command_name}" ]; then
          command_path="/usr/bin/${command_name}"
        elif [ -e "${target}/bin/${command_name}" ]; then
          command_path="/bin/${command_name}"
        else
          continue
        fi
        mark_runtime_provider "$command_path" "env-command:${rel}"
        ;;
      /*)
        [ -e "${target}/${interpreter#/}" ] \
          && mark_runtime_provider "$interpreter" "shebang:${rel}"
        ;;
    esac
  done < <(find "$subject" -type f -print0 | sort -z)

  runtime_dep_total="${#runtime_dep_slots[@]}"
  for slot in ${runtime_dep_slots[@]+"${runtime_dep_slots[@]}"}; do
    dep_name="${runtime_dep_names[$slot]}"
    redundant_via="${runtime_dep_redundant_via[$slot]}"
    if [ "${runtime_dep_seen[$slot]}" -eq 1 ]; then
      runtime_dep_observed=$((runtime_dep_observed + 1))
      runtime_dep_lines+=("observed"$'\t'"${subject_name}"$'\t'"${dep_name}"$'\t'"static"$'\t'"${runtime_dep_evidence[$slot]}")
    elif [ -n "$redundant_via" ]; then
      runtime_dep_redundant=$((runtime_dep_redundant + 1))
      runtime_dep_lines+=("redundant"$'\t'"${subject_name}"$'\t'"${dep_name}"$'\t'"via"$'\t'"${redundant_via}")
    else
      runtime_dep_unobserved=$((runtime_dep_unobserved + 1))
      runtime_dep_lines+=("unobserved"$'\t'"${subject_name}"$'\t'"${dep_name}"$'\t'"-"$'\t'"-")
    fi
  done
fi

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
  echo "runtime dependencies: ${runtime_dep_total}"
  echo "runtime dependencies observed: ${runtime_dep_observed}"
  echo "runtime dependencies unobserved: ${runtime_dep_unobserved}"
  echo "runtime dependencies redundant: ${runtime_dep_redundant}"
  # Sort each group so the report depends only on the SET of findings, not on
  # the order they were discovered in: the scans walk the tree via `find`, which
  # returns readdir order, and that differs between two builds of the same tree
  # on different hosts -- which would make the report (and this node's output
  # hash) non-reproducible even though the findings are identical.
  [ "${#infos[@]}" -eq 0 ] || printf 'INFO  %s\n' "${infos[@]}" | LC_ALL=C sort
  [ "${#supp_fails[@]}" -eq 0 ] || printf 'INFO  approved: %s\n' "${supp_fails[@]}" | LC_ALL=C sort
  [ "${#real_fails[@]}" -eq 0 ] || printf 'FAIL  %s\n' "${real_fails[@]}" | LC_ALL=C sort
  [ "${#runtime_dep_lines[@]}" -eq 0 ] \
    || printf 'RUNTIME_DEP\t%s\n' "${runtime_dep_lines[@]}" | LC_ALL=C sort
  echo "status: ${status}"
  echo "failures: ${#real_fails[@]}"
} > "${dest}/report-${name}-${status}.txt"
