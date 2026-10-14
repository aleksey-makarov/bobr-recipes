#!/usr/bin/env bash

# QEMU runners must use the workspace containing the invoked bobr-recipes path,
# even when that checkout path is a symlink to another repository location.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
temporary="$(mktemp -d)"
trap 'rm -rf "${temporary}"' EXIT

fail() {
  echo "test-qemu-runners.sh: $*" >&2
  exit 1
}

workspace="${temporary}/workspace"
store="${workspace}/bobr-store"
fake_bin="${temporary}/bin"
mkdir -p \
  "${store}/object-refs/linux-bzimage" \
  "${store}/object-refs/initrd" \
  "${store}/object-refs/qemu-image" \
  "${store}/object-refs/qemu-gnome-image" \
  "${fake_bin}"
ln -s "${repo_root}" "${workspace}/bobr-recipes"

printf 'kernel\n' > "${store}/object-refs/linux-bzimage/bzImage"
printf 'initrd\n' > "${store}/object-refs/initrd/initramfs.img"
printf 'rootfs\n' > "${store}/object-refs/qemu-image/erofs-rootfs.erofs"
printf 'gnome rootfs\n' > "${store}/object-refs/qemu-gnome-image/erofs-rootfs.erofs"
printf 'home\n' > "${workspace}/bobr-home.img"

cat > "${fake_bin}/qemu-system-x86_64" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "${QEMU_ARGS:?}"
EOF
chmod +x "${fake_bin}/qemu-system-x86_64"

check_runner() {
  local runner="$1" rootfs_name="$2" args_file
  args_file="${temporary}/${runner}.args"
  QEMU_ARGS="${args_file}" PATH="${fake_bin}:${PATH}" \
    "${workspace}/bobr-recipes/tools/${runner}"

  grep -Fx "${store}/object-refs/linux-bzimage/bzImage" "${args_file}" >/dev/null \
    || fail "${runner} did not use the workspace kernel"
  grep -Fx "${store}/object-refs/initrd/initramfs.img" "${args_file}" >/dev/null \
    || fail "${runner} did not use the workspace initrd"
  grep -F "file=${store}/object-refs/${rootfs_name}/erofs-rootfs.erofs," "${args_file}" >/dev/null \
    || fail "${runner} did not use the workspace rootfs"
  grep -F "file=${workspace}/bobr-home.img," "${args_file}" >/dev/null \
    || fail "${runner} did not use the workspace home image"
}

check_runner bobr-run-qemu.sh qemu-image
check_runner bobr-run-qemu-gnome.sh qemu-gnome-image

echo "QEMU runner tests passed"
