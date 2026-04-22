#!/usr/bin/env bash
set -euo pipefail

phase="${1:-${MBUILD_STEP_NAME:-}}"
phase="${phase:?step name is required}"
source_dir="${MBUILD_SOURCE_DIR:?MBUILD_SOURCE_DIR is required}"
install_dir="${MBUILD_INSTALL_DIR:?MBUILD_INSTALL_DIR is required}"
kernel_config="/__mbuild/inputs/kernel_config"

export ARCH=x86_64
export KBUILD_BUILD_USER=mbuild
export KBUILD_BUILD_HOST=mbuild
export KBUILD_BUILD_TIMESTAMP='1970-01-01'
export KBUILD_BUILD_VERSION=1
export SOURCE_DATE_EPOCH=0
export LC_ALL=C
export TZ=UTC

resolve_source_dir() {
  if [ -f "$source_dir/Makefile" ]; then
    printf '%s\n' "$source_dir"
    return
  fi

  local candidates=()
  local d
  for d in "$source_dir"/*; do
    if [ -d "$d" ] && [ -f "$d/Makefile" ]; then
      candidates+=("$d")
    fi
  done
  if [ "${#candidates[@]}" -eq 1 ]; then
    printf '%s\n' "${candidates[0]}"
    return
  fi

  echo "qemu-kernel build-script: Makefile not found in ${source_dir}" >&2
  exit 1
}

ensure_tmpdir() {
  local project_source_dir tmpdir
  project_source_dir="$(resolve_source_dir)"
  tmpdir="${project_source_dir}/.tmp"
  mkdir -p "$tmpdir"
  export TMPDIR="$tmpdir"
}

phase_configure() {
  local project_source_dir
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  ensure_tmpdir
  make mrproper
  cp "$kernel_config" .config
  make olddefconfig
}

phase_build() {
  local project_source_dir jobs
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  ensure_tmpdir
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"${jobs}" bzImage
}

phase_install() {
  local project_source_dir
  project_source_dir="$(resolve_source_dir)"
  cd "$project_source_dir"
  ensure_tmpdir
  mkdir -p "$install_dir/boot"
  install -m0644 arch/x86/boot/bzImage "$install_dir/boot/bzImage"
  install -m0644 System.map "$install_dir/boot/System.map"
  install -m0644 .config "$install_dir/boot/kernel.config"
}

case "$phase" in
  configure) phase_configure ;;
  build) phase_build ;;
  install) phase_install ;;
  *)
    echo "qemu-kernel build-script: unsupported phase '$phase'" >&2
    exit 1
    ;;
esac
