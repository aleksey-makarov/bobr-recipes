#!/usr/bin/env bash
set -euo pipefail

phase="${MBUILD_STEP_NAME:?MBUILD_STEP_NAME is required}"
source_dir="${1:?source dir is required}"
install_dir="${2:?install dir is required}"
kernel_config="/__mbuild/inputs/kernel_config"

export ARCH=x86_64
export KBUILD_BUILD_USER=mbuild
export KBUILD_BUILD_HOST=mbuild
export KBUILD_BUILD_TIMESTAMP='1970-01-01'
export KBUILD_BUILD_VERSION=1
export SOURCE_DATE_EPOCH=0
export LC_ALL=C
export TZ=UTC

ensure_tmpdir() {
  local tmpdir
  tmpdir="${source_dir}/.tmp"
  mkdir -p "$tmpdir"
  export TMPDIR="$tmpdir"
}

phase_configure() {
  cd "$source_dir"
  ensure_tmpdir
  make mrproper
  cp "$kernel_config" .config
  make olddefconfig
}

phase_build() {
  local jobs
  cd "$source_dir"
  ensure_tmpdir
  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"${jobs}" bzImage
}

phase_install() {
  cd "$source_dir"
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
