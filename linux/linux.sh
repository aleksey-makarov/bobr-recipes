#!/usr/bin/env bash
set -euo pipefail

phase="${BOBR_STEP_NAME:?BOBR_STEP_NAME is required}"
build_kind="${BOBR_LINUX_BUILD_KIND:-full}"
source_dir="${BOBR_SOURCE_DIR:?BOBR_SOURCE_DIR is required}"
install_dir="${BOBR_INSTALL_DIR:?BOBR_INSTALL_DIR is required}"

export ARCH=x86_64
export KBUILD_BUILD_USER=bobr
export KBUILD_BUILD_HOST=bobr
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
    # Base config from the kernel's own defconfig/tinyconfig, then merge our
    # data-driven fragment (materialized via script_config) on top.
    make "${BOBR_LINUX_CONFIG_BASE:?BOBR_LINUX_CONFIG_BASE is required}"
    ./scripts/kconfig/merge_config.sh -m .config "${BOBR_CONFIG_DIR:?BOBR_CONFIG_DIR is required}/config.fragment"
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
  make -j"${jobs}" bzImage modules
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
    # Install loadable modules and let depmod (from kmod) generate
    # modules.dep/.alias/... so udev can autoload by modalias.
    # INSTALL_MOD_STRIP=1 drops debug info to keep the tree small. The kernel
    # hardcodes lib/modules under INSTALL_MOD_PATH; we point it at usr so
    # modules land in usr/lib/modules -- a real directory in the merged rootfs,
    # where /lib is a symlink to usr/lib (installing to lib/modules would
    # collide with that symlink on TreeMerge).
    make INSTALL_MOD_PATH="$install_dir/usr" INSTALL_MOD_STRIP=1 modules_install
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
