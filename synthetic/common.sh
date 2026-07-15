#!/usr/bin/env bash

# A deterministic `uname` shim, placed ahead of coreutils on PATH. Some builds
# embed `uname` output at compile time (e.g. libgtop bakes `uname -r`/`-v` into
# its binaries), which otherwise varies with the build host's kernel and breaks
# reproducibility. uname reads the kernel directly, so the sandbox namespace
# cannot fake it; we shadow the binary instead, as nixpkgs' deterministic-uname
# does. This covers the synthetic builders (which source this file); custom
# SandboxBuild scripts are not affected. Values are host-independent; the kernel
# release can be overridden with BOBR_UNAME_RELEASE.
bobr_setup_tool_shims() {
  local shimdir="${BOBR_BUILD_DIR:?BOBR_BUILD_DIR is required}/.bobr-toolshims"
  mkdir -p "$shimdir"
  cat > "$shimdir/uname" <<'SHIM'
#!/bin/bash
# Deterministic uname (bobr). Host-independent output for reproducible builds.
set -u
: "${BOBR_UNAME_RELEASE:=6.18.0}"
S="Linux"; N="bobr"; R="$BOBR_UNAME_RELEASE"; V="#1 SMP bobr"; M="x86_64"; O="GNU/Linux"
s=0 n=0 r=0 v=0 m=0 o=0 p=0 i=0
all() { s=1 n=1 r=1 v=1 m=1 o=1; }
argc=0
for arg in "$@"; do
  argc=$((argc + 1))
  case "$arg" in
    --) ;;
    --all) all ;;
    --kernel-name) s=1 ;;
    --nodename) n=1 ;;
    --kernel-release) r=1 ;;
    --kernel-version) v=1 ;;
    --machine) m=1 ;;
    --processor) p=1 ;;
    --hardware-platform) i=1 ;;
    --operating-system) o=1 ;;
    --help) echo "Usage: uname [OPTION]..."; exit 0 ;;
    --version) echo "uname (bobr deterministic shim)"; exit 0 ;;
    -*)
      opt="${arg#-}"; j=0
      while [ "$j" -lt "${#opt}" ]; do
        case "${opt:$j:1}" in
          a) all ;; s) s=1 ;; n) n=1 ;; r) r=1 ;; v) v=1 ;;
          m) m=1 ;; p) p=1 ;; i) i=1 ;; o) o=1 ;;
          *) echo "uname: invalid option -- '${opt:$j:1}'" >&2; exit 1 ;;
        esac
        j=$((j + 1))
      done
      ;;
    *) echo "uname: extra operand '$arg'" >&2; exit 1 ;;
  esac
done
[ "$argc" -eq 0 ] && s=1
out=""
[ "$s" = 1 ] && out="$out $S"
[ "$n" = 1 ] && out="$out $N"
[ "$r" = 1 ] && out="$out $R"
[ "$v" = 1 ] && out="$out $V"
[ "$m" = 1 ] && out="$out $M"
# -p/-i are "unknown" like a typical GNU/Linux; omitted from -a (which never
# sets them), printed only when explicitly requested.
[ "$p" = 1 ] && out="$out unknown"
[ "$i" = 1 ] && out="$out unknown"
[ "$o" = 1 ] && out="$out $O"
echo "${out# }"
SHIM
  chmod +x "$shimdir/uname"
  case ":$PATH:" in
    *":$shimdir:"*) ;;
    *) export PATH="$shimdir:$PATH" ;;
  esac
}

bobr_prepare_source() {
  # Runs in every step (before the marker early-return below), so the shim is on
  # PATH for configure/build/install too, not just source preparation.
  bobr_setup_tool_shims

  local source_input="${BOBR_SOURCE_INPUT:?BOBR_SOURCE_INPUT is required}"
  local source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"

  case "$source_dir" in
    ""|"/")
      echo "synthetic build-script: refusing unsafe source dir: ${source_dir}" >&2
      exit 1
      ;;
  esac

  local source_parent
  source_parent="$(dirname "$source_dir")"
  local marker="${source_parent}/.bobr-source-prepared"

  if [ -f "$marker" ]; then
    return
  fi

  if [ -e "$source_dir" ]; then
    rm -rf -- "$source_dir"
  fi
  mkdir -p "$source_dir"

  if [ -d "$source_input" ]; then
    tar -C "$source_input" -cf - . | tar -C "$source_dir" -xf -
  elif [ -f "$source_input" ]; then
    tar -C "$source_dir" -xf "$source_input"
    bobr_normalize_single_archive_root "$source_dir"
  else
    echo "synthetic build-script: source input is neither file nor directory: ${source_input}" >&2
    exit 1
  fi

  bobr_apply_patches "$source_dir"
  touch "$marker"
}

bobr_normalize_single_archive_root() {
  local source_dir="$1"
  local entries=()
  mapfile -d '' entries < <(find "$source_dir" -mindepth 1 -maxdepth 1 -print0 | sort -z)

  if [ "${#entries[@]}" -ne 1 ]; then
    return
  fi

  local wrapper="${entries[0]}"
  if [ ! -d "$wrapper" ] || [ -L "$wrapper" ]; then
    return
  fi

  local children=()
  mapfile -d '' children < <(find "$wrapper" -mindepth 1 -maxdepth 1 -print0 | sort -z)
  if [ "${#children[@]}" -gt 0 ]; then
    mv -- "${children[@]}" "$source_dir/"
  fi
  rmdir "$wrapper"
}

bobr_apply_patches() {
  local source_dir="$1"
  local patch_input
  local patch_file

  export LC_ALL=C
  for patch_input in ${BOBR_PATCH_INPUTS:-}; do
    if [ -f "$patch_input" ]; then
      bobr_apply_patch_file "$source_dir" "$patch_input"
    elif [ -d "$patch_input" ]; then
      for patch_file in "$patch_input"/*.patch; do
        [ -e "$patch_file" ] || continue
        [ -f "$patch_file" ] || continue
        bobr_apply_patch_file "$source_dir" "$patch_file"
      done
    else
      echo "synthetic build-script: patch input is neither file nor directory: ${patch_input}" >&2
      exit 1
    fi
  done
}

bobr_apply_patch_file() {
  local source_dir="$1"
  local patch_file="$2"

  echo "synthetic build-script: applying patch ${patch_file}" >&2
  (
    cd "$source_dir"
    patch -Np1 -i "$patch_file"
  )
}
