# Shared core for the bobr-run-qemu* launchers (plain / weston / gnome). This
# file is SOURCED by the thin per-variant wrappers, which set the VARIANT_*
# knobs below and then call `qemu_run "$@"`.
#
# All three variants build (or cache-hit) their boot artifacts through
# bobr-build.sh and boot pkgs.<IMAGE_ATTR> with pkgs.linux_bzimage and
# pkgs.initrd. They share, uniformly:
#   - user networking, guest :22 forwarded to host :2222 (QEMU_SSH_PORT);
#   - a ttyS0 autologin console multiplexed onto the terminal (mon:stdio);
#   - a ttyS1 diagnostic root console exposed as a host unix socket, which the
#     agent drives with guest-exec.py (--sock <that socket>).
# The graphical variants additionally get a venus virtio-gpu (guest /dev/dri) and
# an sdl window; the plain variant is headless (-display none).
#
# Wrapper contract -- set these before `source`-ing this file:
#   VARIANT_IMAGE_ATTR   pkgs attribute of the erofs image (e.g. qemu_image)
#   VARIANT_GRAPHICAL    1 = venus GPU + window, 0 = headless
#   VARIANT_MEM_DEFAULT  default RAM in MiB (QEMU_MEM_MB overrides)
#   VARIANT_HOME_IMG     default /home disk basename (QEMU_HOME_IMG overrides)
#   VARIANT_DIAG_SOCK    default diag socket basename (QEMU_DIAG_SOCK overrides)

APPEND="root=/dev/vda ro rootfstype=erofs systemd.volatile=overlay console=ttyS0 net.ifnames=0"

script_name="$(basename "$0")"

die() {
  echo "${script_name}: $*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: ${script_name} [--store PATH] [-- QEMU_ARG ...]

Boots pkgs.${VARIANT_IMAGE_ATTR} with pkgs.linux_bzimage and pkgs.initrd.
  --store         store dir (default <recipes>/../bobr-store, as bobr-build.sh).
  QEMU_MEM_MB     RAM in MiB (default ${VARIANT_MEM_DEFAULT}).
  QEMU_SMP        vCPUs (default 2).
  QEMU_SSH_PORT   host port forwarded to guest :22 (default 2222).
  QEMU_HOME_IMG   persistent ext4 /home disk (default <recipes>/../${VARIANT_HOME_IMG});
                  auto-created sparse (1 GiB) if missing.
  QEMU_DIAG_SOCK  ttyS1 diag unix socket for guest-exec.py (default ./${VARIANT_DIAG_SOCK}).
EOF
  if [ "${VARIANT_GRAPHICAL}" = 1 ]; then
    cat <<EOF
  QEMU_DISPLAY    qemu display backend (default 'sdl,gl=on'; 'none' for headless,
                  e.g. just to check /dev/dri/card0 on a host with no display).
EOF
  fi
}

qemu_run() {
  local script_path recipes_path store_path="" qemu_args=()
  script_path="$(readlink -f "$0")"
  recipes_path="$(cd "$(dirname "${script_path}")/.." && pwd)"

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --store)
        [ "$#" -ge 2 ] || die "$1 requires a value"
        store_path="$2"
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

  # Resolve the store exactly as bobr-build.sh does: an explicit absolute
  # --store, otherwise <recipes>/../bobr-store.
  [ -n "${store_path}" ] \
    || store_path="$(realpath -ms -- "${recipes_path}/../bobr-store")"
  case "${store_path}" in
    /*) ;;
    *) die "store path must be absolute: ${store_path}" ;;
  esac

  command -v qemu-system-x86_64 >/dev/null 2>&1 \
    || die "qemu-system-x86_64 not found in PATH"
  [ -e /dev/kvm ] \
    || die "/dev/kvm is not available; this smoke check requires KVM acceleration"

  # Build one artifact by pkgs attribute; bobr-build.sh prints its object hash on
  # stdout (progress goes to stderr). `set -e` aborts if a build fails.
  build_object() {
    echo "building ${1} ..." >&2
    "${recipes_path}/tools/bobr-build.sh" --store "${store_path}" "$1"
  }

  local kernel_path image_path initrd_path
  kernel_path="${store_path}/objects/$(build_object linux_bzimage)/bzImage"
  image_path="${store_path}/objects/$(build_object "${VARIANT_IMAGE_ATTR}")/erofs-rootfs.erofs"
  initrd_path="${store_path}/objects/$(build_object initrd)"
  [ -f "${kernel_path}" ] || die "kernel image not found: ${kernel_path}"
  [ -f "${image_path}" ] || die "EROFS rootfs not found: ${image_path}"
  [ -f "${initrd_path}" ] || die "initrd not found: ${initrd_path}"

  # Persistent /home on a second virtio-blk disk (guest /dev/vdb, mounted at
  # /home via fstab). Mutable user state, not a build artifact, so it lives
  # outside the store; each variant defaults to its own file. Create sparse and
  # format ext4 on first use; reuse on later runs.
  local home_img
  home_img="${QEMU_HOME_IMG:-$(realpath -ms -- "${recipes_path}/../${VARIANT_HOME_IMG}")}"
  if [ ! -e "${home_img}" ]; then
    command -v mkfs.ext4 >/dev/null 2>&1 \
      || die "mkfs.ext4 not found (needed to create ${home_img})"
    echo "creating persistent home disk: ${home_img} (sparse 1 GiB ext4)" >&2
    truncate -s 1G "${home_img}" || die "failed to allocate ${home_img}"
    mkfs.ext4 -q -F -E lazy_itable_init=1,lazy_journal_init=1 "${home_img}" \
      || die "mkfs.ext4 failed on ${home_img}"
  fi

  local mem_mb diag_sock
  mem_mb="${QEMU_MEM_MB:-${VARIANT_MEM_DEFAULT}}"

  # Second serial (guest ttyS1) exposed as a host unix socket in the current
  # directory, so the agent can drive the guest's autologin-root diag console
  # over it (see guest-exec.py). Relative path -> lands where you launch this;
  # each variant defaults to its own name so several guests can run at once.
  # Remove a stale socket first so qemu can rebind on a rerun.
  diag_sock="${QEMU_DIAG_SOCK:-${VARIANT_DIAG_SOCK}}"
  rm -f "${diag_sock}"

  # Common core: kernel/initrd/rootfs + persistent /home, user networking (ssh
  # forwarded to :2222), the ttyS0 console on the terminal (mon:stdio) and the
  # ttyS1 diag console on the unix socket.
  local args=(
    -enable-kvm
    -cpu host
    -m "${mem_mb}"
    -smp "${QEMU_SMP:-2}"
    -kernel "${kernel_path}"
    -initrd "${initrd_path}"
    -drive "file=${image_path},format=raw,if=virtio,readonly=on"
    -drive "file=${home_img},format=raw,if=virtio"
    -nic "user,model=virtio-net-pci,hostfwd=tcp::${QEMU_SSH_PORT:-2222}-:22"
    -serial mon:stdio
    -chardev "socket,id=diag,path=${diag_sock},server=on,wait=off"
    -serial chardev:diag
  )

  if [ "${VARIANT_GRAPHICAL}" = 1 ]; then
    # virtio-gpu-gl with venus=true exposes a Vulkan (venus) GPU to the guest;
    # blob resources + hostmem need a shared memory backend (memfd, share=on)
    # wired via -machine memory-backend=mem. -vga none leaves virtio-gpu-gl as
    # the only display adapter; virtio input gives a keyboard and a tablet.
    args=(
      -object "memory-backend-memfd,id=mem,size=${mem_mb}M,share=on"
      -machine memory-backend=mem
      "${args[@]}"
      -vga none
      -device virtio-gpu-gl,blob=true,hostmem=4G,venus=true
      -display "${QEMU_DISPLAY:-sdl,gl=on}"
      -device virtio-keyboard-pci
      -device virtio-tablet-pci
    )
  else
    args+=(-display none)
  fi

  args+=(-append "${APPEND}" -no-reboot "${qemu_args[@]}")
  exec qemu-system-x86_64 "${args[@]}"
}
