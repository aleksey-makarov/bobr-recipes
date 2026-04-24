#!/usr/bin/env bash

# Boot the locally built qemu rootfs artifact under qemu-system-x86_64.
# Use this after qemu-rootfs and qemu-kernel have already been built and
# you want an interactive runtime smoke check of the image.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${repo_root}/env.sh"
rootfs_path="${store_root}/object-refs/qemu-rootfs"
kernel_path="${store_root}/object-refs/qemu-kernel/boot/bzImage"
qemu_bin="$(command -v qemu-system-x86_64 || true)"
mem_mb="${QEMU_MEM_MB:-1024}"
smp_count="${QEMU_SMP:-2}"
append="root=/dev/vda rw console=ttyS0 net.ifnames=0"

if [ -z "${qemu_bin}" ]; then
  echo "qemu-system-x86_64 not found in PATH" >&2
  exit 1
fi

if [ ! -f "${rootfs_path}" ]; then
  echo "missing qemu rootfs artifact: ${rootfs_path}" >&2
  exit 1
fi

if [ ! -f "${kernel_path}" ]; then
  echo "missing qemu kernel artifact: ${kernel_path}" >&2
  exit 1
fi

exec "${qemu_bin}" \
  -m "${mem_mb}" \
  -smp "${smp_count}" \
  -kernel "${kernel_path}" \
  -drive "file=${rootfs_path},format=raw,if=virtio" \
  -nic user,model=virtio-net-pci \
  -append "${append}" \
  -nographic \
  -no-reboot \
  "$@"
