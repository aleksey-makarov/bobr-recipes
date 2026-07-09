#!/usr/bin/env bash

# Build (or cache-hit) the boot artifacts and boot them under
# qemu-system-x86_64. Each artifact is built through bobr-build.sh, which prints
# the resulting object hash on stdout; the object is then read straight from
# <store>/objects/<hash>, so this tool needs no knowledge of the store's
# object-refs layout or of recipe names.
#
# Boots pkgs.erofs_rootfs with pkgs.linux_bzimage and pkgs.initrd.
#
# Usage: bobr-run-qemu.sh [--store PATH] [-- QEMU_ARG ...]
#   --store defaults to <recipes>/../bobr-store, matching bobr-build.sh.
#   QEMU_MEM_MB (default 1024) and QEMU_SMP (default 2) tune the VM.
#   QEMU_HOME_IMG (default <recipes>/../home.img) is a persistent ext4 disk
#   mounted at /home in the guest; auto-created sparse (1 GiB) if missing.

set -euo pipefail

APPEND="root=/dev/vda ro rootfstype=erofs systemd.volatile=overlay console=ttyS0 net.ifnames=0"

die() {
  echo "bobr-run-qemu.sh: $*" >&2
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
image_path="${store_path}/objects/$(build_object erofs_rootfs)/erofs-rootfs.erofs"
initrd_path="${store_path}/objects/$(build_object initrd)"

[ -f "${kernel_path}" ] || die "kernel image not found: ${kernel_path}"
[ -f "${image_path}" ] || die "EROFS rootfs not found: ${image_path}"
[ -f "${initrd_path}" ] || die "initrd not found: ${initrd_path}"

# Persistent /home on a second virtio-blk disk (guest /dev/vdb, mounted at /home
# via fstab -- the same fstab is shared with the gnome rootfs). This is mutable
# user state, not a build artifact, so it lives outside the store. Create it
# sparse and format ext4 on first use; reuse it on later runs. Defaults to a
# separate file from the gnome runner; set QEMU_HOME_IMG to the same path in
# both to share one /home.
home_img="${QEMU_HOME_IMG:-$(realpath -ms -- "${recipes_path}/../home.img")}"
if [ ! -e "${home_img}" ]; then
  command -v mkfs.ext4 >/dev/null 2>&1 || die "mkfs.ext4 not found (needed to create ${home_img})"
  echo "creating persistent home disk: ${home_img} (sparse 1 GiB ext4)" >&2
  truncate -s 1G "${home_img}" || die "failed to allocate ${home_img}"
  mkfs.ext4 -q -F -E lazy_itable_init=1,lazy_journal_init=1 "${home_img}" \
    || die "mkfs.ext4 failed on ${home_img}"
fi

exec qemu-system-x86_64 \
  -enable-kvm \
  -cpu host \
  -m "${QEMU_MEM_MB:-1024}" \
  -smp "${QEMU_SMP:-2}" \
  -kernel "${kernel_path}" \
  -initrd "${initrd_path}" \
  -drive "file=${image_path},format=raw,if=virtio,readonly=on" \
  -drive "file=${home_img},format=raw,if=virtio" \
  -nic user,model=virtio-net-pci \
  -append "${APPEND}" \
  -nographic \
  -no-reboot \
  "${qemu_args[@]}"
