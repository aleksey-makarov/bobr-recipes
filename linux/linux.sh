#!/usr/bin/env bash
set -euo pipefail

phase="${MBUILD_STEP_NAME:?MBUILD_STEP_NAME is required}"
build_kind="${MBUILD_LINUX_BUILD_KIND:-full}"
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

  if [ "$build_kind" = "full" ]; then
    cp "$kernel_config" .config
    make olddefconfig
  fi
}

phase_build() {
  local jobs

  cd "$source_dir"
  ensure_tmpdir

  if [ "$build_kind" = "headers" ]; then
    make headers
    find usr/include -type f ! -name '*.h' -delete
    return
  fi

  jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
  make -j"${jobs}" bzImage
}

install_headers_with_rsync() {
  mkdir -p "$install_dir/usr"
  make headers_install INSTALL_HDR_PATH="$install_dir/usr"
}

install_bootstrap_headers() {
  mkdir -p "$install_dir/usr"
  cp -rv usr/include "$install_dir/usr"
}

phase_install() {
  cd "$source_dir"
  ensure_tmpdir

  if [ "$build_kind" = "full" ]; then
    mkdir -p "$install_dir/boot"
    install -m0644 arch/x86/boot/bzImage "$install_dir/boot/bzImage"
    install -m0644 System.map "$install_dir/boot/System.map"
    install -m0644 .config "$install_dir/boot/kernel.config"
    install_headers_with_rsync
  else
    install_bootstrap_headers
  fi
}

case "$phase" in
  configure) phase_configure ;;
  build) phase_build ;;
  install) phase_install ;;
  *)
    echo "linux build-script: unsupported phase '$phase'" >&2
    exit 1
    ;;
esac
