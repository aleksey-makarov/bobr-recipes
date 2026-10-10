#!/usr/bin/env bash
# Boot the GNOME QEMU image using host QEMU and the adjacent Bobr store.
set -euo pipefail

die() {
  echo "bobr-run-qemu-gnome.sh: $*" >&2
  exit 1
}

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
workspace="$(dirname "$(dirname "$(dirname "$script_path")")")"
store="${workspace}/bobr-store"
kernel="${store}/object-refs/linux-bzimage/bzImage"
initrd="${store}/object-refs/initrd/initramfs.img"
rootfs="${store}/object-refs/qemu-gnome-image/erofs-rootfs.erofs"
home_image="${workspace}/bobr-home.img"

for artifact in "$kernel" "$initrd" "$rootfs"; do
  [[ -f "$artifact" && -r "$artifact" && -s "$artifact" ]] ||
    die "missing, empty, or unreadable boot artifact: ${artifact}"
done
command -v qemu-system-x86_64 >/dev/null || die "qemu-system-x86_64 is not on PATH"

if [[ -e "$home_image" || -L "$home_image" ]]; then
  [[ -f "$home_image" && -r "$home_image" && -w "$home_image" && -s "$home_image" ]] ||
    die "home image must be a nonempty, readable, writable regular file: ${home_image}"
else
  command -v mkfs.ext4 >/dev/null || die "mkfs.ext4 is not on PATH"
  temporary_image="$(mktemp "${home_image}.XXXXXX")"
  trap 'rm -f -- "$temporary_image"' EXIT
  truncate -s 1G "$temporary_image"
  mkfs.ext4 -q "$temporary_image"
  mv -- "$temporary_image" "$home_image"
  trap - EXIT
fi

exec qemu-system-x86_64 \
  -object memory-backend-memfd,id=mem,size=4096M,share=on \
  -enable-kvm -cpu host -machine q35,memory-backend=mem -m 4096 -smp 2 \
  -kernel "$kernel" -initrd "$initrd" \
  -drive "file=${rootfs},format=raw,if=virtio,readonly=on" \
  -drive "file=${home_image},format=raw,if=virtio" \
  -nic user,model=virtio-net-pci \
  -vga none -device virtio-gpu-gl,blob=true,hostmem=4G,venus=true \
  -display sdl,gl=on -serial mon:stdio \
  -device virtio-keyboard-pci -device virtio-tablet-pci \
  -append "root=/dev/vda ro rootfstype=erofs systemd.volatile=overlay console=ttyS0 net.ifnames=0" \
  -no-reboot "$@"
