#!/usr/bin/env bash

# Boot the QEMU image embedded in a QEMU HostBundle. The immutable boot
# artifacts and fixed variant settings are supplied by the launcher through
# BOBR_QEMU_*; only the persistent home image and diagnostic socket live
# outside the bundle.

set -euo pipefail

script_name="${0##*/}"

die() {
  echo "${script_name}: $*" >&2
  exit 1
}

usage() {
  echo "Usage: ${script_name} [OPTION]... [-- QEMU_ARG...]"
  echo
  echo "  --home-image PATH  persistent ext4 /home image (default ./${default_home_image})"
  echo "  --diag-sock PATH   ttyS1 diagnostic socket (default ./${default_diag_sock})"
  echo "  --memory MIB       guest RAM (default ${default_memory})"
  echo "  --smp N            guest vCPUs (default 2)"
  echo "  --ssh-port PORT    forward host PORT to guest port 22 (default 2222)"
  if [ "$graphical" = 1 ]; then
    echo "  BOBR_QEMU_DISPLAY  QEMU display backend (default sdl,gl=on)"
  fi
  echo "  -h, --help         show this help"
}

rootfs="${BOBR_QEMU_ROOTFS:?BOBR_QEMU_ROOTFS is not set by the bundle launcher}"
kernel="${BOBR_QEMU_KERNEL:?BOBR_QEMU_KERNEL is not set by the bundle launcher}"
initrd="${BOBR_QEMU_INITRD:?BOBR_QEMU_INITRD is not set by the bundle launcher}"
variant="${BOBR_QEMU_VARIANT:?BOBR_QEMU_VARIANT is not set by the bundle launcher}"
graphical="${BOBR_QEMU_GRAPHICAL:?BOBR_QEMU_GRAPHICAL is not set by the bundle launcher}"
default_home_image="${BOBR_QEMU_DEFAULT_HOME_IMAGE:?BOBR_QEMU_DEFAULT_HOME_IMAGE is not set by the bundle launcher}"
default_diag_sock="${BOBR_QEMU_DEFAULT_DIAG_SOCK:?BOBR_QEMU_DEFAULT_DIAG_SOCK is not set by the bundle launcher}"
default_memory="${BOBR_QEMU_DEFAULT_MEMORY_MIB:?BOBR_QEMU_DEFAULT_MEMORY_MIB is not set by the bundle launcher}"

case "$graphical" in
  0 | 1) ;;
  *) die "invalid bundled graphical mode for ${variant}: ${graphical}" ;;
esac

home_image="${BOBR_QEMU_HOME_IMAGE:-${PWD}/${default_home_image}}"
diag_sock="${BOBR_QEMU_DIAG_SOCK:-${PWD}/${default_diag_sock}}"
memory="${BOBR_QEMU_MEMORY_MIB:-${default_memory}}"
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

# q35 is the modern emulated chipset: it has a PCI Express root complex and
# publishes the ACPI MCFG table, so the guest can reach extended PCI config
# space. QEMU still defaults to "pc" -- i440FX, a chipset that predates PCIe --
# where the kernel reports at every boot that it cannot.
#
# Venus blob resources additionally need the machine's memory to be shareable,
# hence the memory-backend property on the graphical variant.
machine="q35"
if [ "$graphical" = 1 ]; then
  machine="q35,memory-backend=mem"
fi

launch_args=(
  -enable-kvm
  -cpu host
  -machine "$machine"
  -m "$memory"
  -smp "$smp"
  -kernel "$kernel"
  -initrd "$initrd"
  -drive "file=${rootfs},format=raw,if=virtio,readonly=on"
  -drive "file=${home_image},format=raw,if=virtio"
  -nic "user,model=virtio-net-pci,hostfwd=tcp::${ssh_port}-:22"
  -serial mon:stdio
  -chardev "socket,id=diag,path=${diag_sock},server=on,wait=off"
  -serial chardev:diag
)

if [ "$graphical" = 1 ]; then
  # The SDL/Wayland window and virtio input devices match the graphical
  # development runners; the shared memory backend is named by -machine above.
  launch_args=(
    -object "memory-backend-memfd,id=mem,size=${memory}M,share=on"
    "${launch_args[@]}"
    -vga none
    -device "virtio-gpu-gl,blob=true,hostmem=4G,venus=true"
    -display "${BOBR_QEMU_DISPLAY:-sdl,gl=on}"
    -device virtio-keyboard-pci
    -device virtio-tablet-pci
  )
else
  launch_args+=(-display none)
fi

launch_args+=(-append "$append" -no-reboot "${qemu_args[@]}")
exec qemu-system-x86_64 "${launch_args[@]}"
