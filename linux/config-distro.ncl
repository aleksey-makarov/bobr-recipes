# Distro-like kernel configuration, expressed as data and merged on top of
# `make defconfig` (see `kconfig_fragment` in linux.ncl). This is the base;
# `linux.config_options` is layered over it (right-biased), so an overlay
# overrides or adds individual options without restating this set:
#
#   linux = prev.linux & {
#     config_options = prev.linux.config_options & { VIRTIO_GPU = 'y },
#   }
#
# Values:
#   'y      -> CONFIG_X=y            (built into the kernel)
#   'm      -> CONFIG_X=m            (loadable module)
#   'n      -> # CONFIG_X is not set (disabled)
#   number  -> CONFIG_X=<n>
#   string  -> CONFIG_X="<s>"
# Keys omit the CONFIG_ prefix.
#
# Intentionally a focused, useful baseline (VM + container essentials) meant to
# grow over time -- not a full distribution config.
{
  # Loadable-module support (modular, distro-style kernel).
  MODULES = 'y,
  MODULE_UNLOAD = 'y,

  # Namespaces, cgroups, seccomp -- container-runtime essentials.
  NAMESPACES = 'y,
  USER_NS = 'y,
  PID_NS = 'y,
  NET_NS = 'y,
  UTS_NS = 'y,
  IPC_NS = 'y,
  CGROUPS = 'y,
  MEMCG = 'y,
  CGROUP_PIDS = 'y,
  CGROUP_FREEZER = 'y,
  CGROUP_SCHED = 'y,
  CPUSETS = 'y,
  # eBPF attached to cgroups: lets systemd enforce IPAddressAllow/Deny (and
  # SocketBind*/RestrictNetworkInterfaces) via a cgroup/skb BPF program instead
  # of skipping them with a "does not support BPF/cgroup firewalling" warning.
  # BPF_SYSCALL selects BPF; CGROUP_BPF depends on it.
  BPF_SYSCALL = 'y,
  CGROUP_BPF = 'y,
  SECCOMP = 'y,

  # Filesystems.
  EXT4_FS = 'y,
  BTRFS_FS = 'm,
  XFS_FS = 'm,
  F2FS_FS = 'm,
  VFAT_FS = 'y,
  EXFAT_FS = 'm,
  ISO9660_FS = 'm,
  SQUASHFS = 'm,
  EROFS_FS = 'y,
  OVERLAY_FS = 'y,
  FUSE_FS = 'm,
  AUTOFS_FS = 'm,
  NFS_FS = 'm,
  TMPFS = 'y,
  TMPFS_POSIX_ACL = 'y,
  DEVTMPFS = 'y,
  DEVTMPFS_MOUNT = 'y,

  # Block layer.
  BLK_DEV_LOOP = 'y,
  BLK_DEV_NVME = 'm,
  BLK_DEV_DM = 'm,
  DM_CRYPT = 'm,

  # virtio (QEMU/KVM guests).
  VIRTIO_PCI = 'y,
  VIRTIO_BLK = 'm,
  VIRTIO_NET = 'm,
  VIRTIO_CONSOLE = 'm,
  VIRTIO_BALLOON = 'm,
  VIRTIO_INPUT = 'm,
  SCSI_VIRTIO = 'm,

  # Networking basics + container plumbing.
  BRIDGE = 'm,
  VETH = 'm,
  TUN = 'm,
  NETFILTER = 'y,

  # Firmware / boot.
  EFI = 'y,
  EFI_STUB = 'y,

  # Graphics: DRM/KMS + virtio-gpu, so a QEMU guest gets /dev/dri/card0 (see
  # tools/bobr-run-qemu-gnome.sh). Pinned explicitly rather than inherited from
  # `make defconfig`, so the graphics foundation is reproducible and does not
  # drift when the kernel version or base config changes. DRM_FBDEV_EMULATION +
  # FRAMEBUFFER_CONSOLE put the console on the DRM framebuffer; INPUT_EVDEV
  # exposes /dev/input/event* for userspace input (libinput).
  DRM = 'y,
  DRM_VIRTIO_GPU = 'y,
  DRM_FBDEV_EMULATION = 'y,
  FB = 'y,
  FRAMEBUFFER_CONSOLE = 'y,
  INPUT_EVDEV = 'm,

  # Local build tag.
  LOCALVERSION = "-bobr",
}
