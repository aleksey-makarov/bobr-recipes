#!/usr/bin/env bash

# Boot the locally built EROFS rootfs artifact under qemu-system-x86_64.
# Use this after erofs-rootfs, initrd, and linux have already been built and
# you want an interactive runtime smoke check of the image.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${repo_root}/env.sh"
linux_name="$(
  cd "${repo_root}"
  printf '%s\n' 'let pkgs = (import "pkgs.ncl") [] in pkgs.linux.name' \
    | nickel export --format text
)"
rootfs_name="$(
  cd "${repo_root}"
  printf '%s\n' 'let pkgs = (import "pkgs.ncl") [] in pkgs.erofs_rootfs.name' \
    | nickel export --format text
)"
initrd_name="$(
  cd "${repo_root}"
  printf '%s\n' 'let pkgs = (import "pkgs.ncl") [] in pkgs.initrd.name' \
    | nickel export --format text
)"
rootfs_path="${store_root}/object-refs/${rootfs_name}"
initrd_path="${store_root}/object-refs/${initrd_name}"
kernel_path="${store_root}/object-refs/${linux_name}/root/boot/bzImage"
qemu_bin="$(command -v qemu-system-x86_64 || true)"
mem_mb="${QEMU_MEM_MB:-1024}"
smp_count="${QEMU_SMP:-2}"
append="root=/dev/vda ro rootfstype=erofs systemd.volatile=overlay console=ttyS0 net.ifnames=0"

if [ -z "${qemu_bin}" ]; then
  echo "qemu-system-x86_64 not found in PATH" >&2
  exit 1
fi

if [ ! -f "${rootfs_path}" ]; then
  echo "missing EROFS rootfs artifact for ${rootfs_name}: ${rootfs_path}" >&2
  exit 1
fi

if [ ! -f "${initrd_path}" ]; then
  echo "missing initrd artifact for ${initrd_name}: ${initrd_path}" >&2
  exit 1
fi

if [ ! -f "${kernel_path}" ]; then
  echo "missing linux kernel artifact for ${linux_name}: ${kernel_path}" >&2
  exit 1
fi

if [ ! -e /dev/kvm ]; then
  echo "/dev/kvm is not available; this smoke check requires KVM acceleration" >&2
  exit 1
fi

exec "${qemu_bin}" \
  -enable-kvm \
  -cpu host \
  -m "${mem_mb}" \
  -smp "${smp_count}" \
  -kernel "${kernel_path}" \
  -initrd "${initrd_path}" \
  -drive "file=${rootfs_path},format=raw,if=virtio,readonly=on" \
  -nic user,model=virtio-net-pci \
  -append "${append}" \
  -nographic \
  -no-reboot \
  "$@"
