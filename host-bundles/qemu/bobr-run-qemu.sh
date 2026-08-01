#!/usr/bin/env bash

# Boot the QEMU image embedded in host-bundle-qemu. The immutable boot
# artifacts are supplied by the launcher through BOBR_QEMU_*; only the
# persistent home image and diagnostic socket live outside the bundle.

set -euo pipefail

script_name="${0##*/}"

die() {
  echo "${script_name}: $*" >&2
  exit 1
}

usage() {
  echo "Usage: ${script_name} [OPTION]... [-- QEMU_ARG...]"
  echo
  echo "  --home-image PATH  persistent ext4 /home image (default ./home.img)"
  echo "  --diag-sock PATH   ttyS1 diagnostic socket (default ./diag.sock)"
  echo "  --memory MIB       guest RAM (default 1024)"
  echo "  --smp N            guest vCPUs (default 2)"
  echo "  --ssh-port PORT    forward host PORT to guest port 22 (default 2222)"
  echo "  -h, --help         show this help"
}

rootfs="${BOBR_QEMU_ROOTFS:?BOBR_QEMU_ROOTFS is not set by the bundle launcher}"
kernel="${BOBR_QEMU_KERNEL:?BOBR_QEMU_KERNEL is not set by the bundle launcher}"
initrd="${BOBR_QEMU_INITRD:?BOBR_QEMU_INITRD is not set by the bundle launcher}"
home_image="${BOBR_QEMU_HOME_IMAGE:-${PWD}/home.img}"
diag_sock="${BOBR_QEMU_DIAG_SOCK:-${PWD}/diag.sock}"
memory="${BOBR_QEMU_MEMORY_MIB:-1024}"
smp="${BOBR_QEMU_SMP:-2}"
ssh_port="${BOBR_QEMU_SSH_PORT:-2222}"
qemu_args=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --home-image)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      home_image="$2"
      shift 2
      ;;
    --diag-sock)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      diag_sock="$2"
      shift 2
      ;;
    --memory)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      memory="$2"
      shift 2
      ;;
    --smp)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      smp="$2"
      shift 2
      ;;
    --ssh-port)
      [ "$#" -ge 2 ] || die "$1 requires a value"
      ssh_port="$2"
      shift 2
      ;;
    -h | --help)
      usage
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

[ -f "$rootfs" ] || die "bundled rootfs image is missing: $rootfs"
[ -f "$kernel" ] || die "bundled kernel image is missing: $kernel"
[ -f "$initrd" ] || die "bundled initramfs is missing: $initrd"
[ -e /dev/kvm ] || die "/dev/kvm is not available"

if [ ! -e "$home_image" ]; then
  echo "creating persistent home disk: $home_image (sparse 1 GiB ext4)" >&2
  truncate -s 1G "$home_image" || die "failed to allocate $home_image"
  mkfs.ext4 -q -F -E lazy_itable_init=1,lazy_journal_init=1 "$home_image" \
    || die "mkfs.ext4 failed on $home_image"
fi

rm -f "$diag_sock"

append="root=/dev/vda ro rootfstype=erofs systemd.volatile=overlay console=ttyS0 net.ifnames=0"

exec qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m "$memory" \
  -smp "$smp" \
  -kernel "$kernel" \
  -initrd "$initrd" \
  -drive "file=${rootfs},format=raw,if=virtio,readonly=on" \
  -drive "file=${home_image},format=raw,if=virtio" \
  -nic "user,model=virtio-net-pci,hostfwd=tcp::${ssh_port}-:22" \
  -serial mon:stdio \
  -chardev "socket,id=diag,path=${diag_sock},server=on,wait=off" \
  -serial chardev:diag \
  -display none \
  -append "$append" \
  -no-reboot \
  "${qemu_args[@]}"
