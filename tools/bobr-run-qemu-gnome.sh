#!/usr/bin/env bash

# GNOME variant of bobr-run-qemu.sh: same boot artifacts, but qemu presents a
# virtio-gpu (DRM/KMS) device and a graphical window, so the guest gets
# /dev/dri/card0 and can eventually run a graphical session. The serial console
# is kept on the terminal (console=ttyS0) for debugging alongside the window.
#
# Boots pkgs.gnome_erofs_rootfs with pkgs.linux_bzimage and pkgs.initrd.
#
# Usage: bobr-run-qemu-gnome.sh [--store PATH] [-- QEMU_ARG ...]
#   --store defaults to <recipes>/../bobr-store, matching bobr-build.sh.
#   QEMU_MEM_MB (default 4096) and QEMU_SMP (default 2) tune the VM.
#   QEMU_DISPLAY (default 'sdl,gl=on') selects the qemu display backend; set it
#   to 'none' for a headless run (e.g. just to check /dev/dri/card0) when the
#   host has no display/OpenGL.

set -euo pipefail

APPEND="root=/dev/vda ro rootfstype=erofs systemd.volatile=overlay console=ttyS0 net.ifnames=0"

die() {
  echo "bobr-run-qemu-gnome.sh: $*" >&2
  exit 1
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
recipes_path="$(cd "$(dirname "${script_path}")/.." && pwd)"

store_path=""
qemu_args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --store)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      store_path="$2"
      shift 2
      ;;
    -h | --help)
      sed -n '3,16p' "${script_path}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --)
      shift
      qemu_args=("$@")
      break
      ;;
    *)
      die "unexpected argument '$1' (did you mean '-- $1'?)"
      ;;
  esac
done

# Resolve the store exactly as bobr-build.sh does: an explicit absolute --store,
# otherwise <recipes>/../bobr-store.
if [ -z "${store_path}" ]; then
  store_path="$(realpath -ms -- "${recipes_path}/../bobr-store")"
fi
case "${store_path}" in
  /*) ;;
  *) die "store path must be absolute: ${store_path}" ;;
esac

command -v qemu-system-x86_64 >/dev/null 2>&1 || die "qemu-system-x86_64 not found in PATH"
[ -e /dev/kvm ] || die "/dev/kvm is not available; this smoke check requires KVM acceleration"

# Build one artifact by pkgs attribute; bobr-build.sh prints its object hash on
# stdout (progress goes to stderr). `set -e` aborts if a build fails. The
# progress note goes to stderr so it does not pollute the captured hash.
build_object() {
  echo "building ${1} ..." >&2
  "${recipes_path}/tools/bobr-build.sh" --store "${store_path}" "$1"
}

kernel_path="${store_path}/objects/$(build_object linux_bzimage)/bzImage"
image_path="${store_path}/objects/$(build_object gnome_erofs_rootfs)/erofs-rootfs.erofs"
initrd_path="${store_path}/objects/$(build_object initrd)"

[ -f "${kernel_path}" ] || die "kernel image not found: ${kernel_path}"
[ -f "${image_path}" ] || die "EROFS rootfs not found: ${image_path}"
[ -f "${initrd_path}" ] || die "initrd not found: ${initrd_path}"

# virtio-vga-gl provides the virtio-gpu (DRM card0) plus VGA compatibility and
# virgl acceleration; -vga none disables the default emulated VGA so it is the
# only display adapter. virtio input devices give the guest a keyboard and a
# tablet (absolute pointer). The serial console stays multiplexed on stdio via
# -serial mon:stdio (replacing the base script's -nographic).
exec qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m "${QEMU_MEM_MB:-4096}" \
  -smp "${QEMU_SMP:-2}" \
  -kernel "${kernel_path}" \
  -initrd "${initrd_path}" \
  -drive "file=${image_path},format=raw,if=virtio,readonly=on" \
  -nic user,model=virtio-net-pci \
  -vga none \
  -device virtio-vga-gl \
  -display "${QEMU_DISPLAY:-sdl,gl=on}" \
  -device virtio-keyboard-pci \
  -device virtio-tablet-pci \
  -serial mon:stdio \
  -append "${APPEND}" \
  -no-reboot \
  "${qemu_args[@]}"
