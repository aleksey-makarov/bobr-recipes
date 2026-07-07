# Minimal-monolithic kernel configuration, merged on top of `make tinyconfig`
# when `linux.use_tinyconfig = true`. Same data model as distro-config.ncl;
# `linux.config_options` is layered over it (right-biased).
#
# Everything is built in (`'y`) and modules are off: the initrd ships no .ko
# and we do not build modules, so anything needed to boot must be in-kernel.
# This is a best-effort starting set to bring up the current `bobr-run-qemu.sh`
# path (direct -kernel/-initrd boot, root=/dev/vda rootfstype=erofs,
# console=ttyS0, systemd.volatile=overlay, virtio-net); it is NOT yet debugged.
{
  # Monolithic: no loadable modules.
  MODULES = 'n,

  # Core.
  "64BIT" = 'y,
  MULTIUSER = 'y,
  PRINTK = 'y,
  BINFMT_ELF = 'y,
  FUTEX = 'y,
  EPOLL = 'y,
  SIGNALFD = 'y,
  TIMERFD = 'y,
  EVENTFD = 'y,
  FHANDLE = 'y,
  INOTIFY_USER = 'y,
  FILE_LOCKING = 'y,
  BLOCK = 'y,
  BLK_DEV = 'y,
  BLK_DEV_INITRD = 'y,

  # Console over the QEMU serial port (console=ttyS0).
  TTY = 'y,
  SERIAL_8250 = 'y,
  SERIAL_8250_CONSOLE = 'y,

  # Bus / virtio (QEMU guest).
  PCI = 'y,
  VIRTIO = 'y,
  VIRTIO_PCI = 'y,
  VIRTIO_BLK = 'y,
  VIRTIO_NET = 'y,
  VIRTIO_CONSOLE = 'y,

  # Networking (virtio-net + basic stack).
  NET = 'y,
  INET = 'y,
  PACKET = 'y,
  UNIX = 'y,

  # cgroups -- required by systemd (the initrd init).
  CGROUPS = 'y,
  MEMCG = 'y,

  # Pseudo + boot filesystems.
  PROC_FS = 'y,
  PROC_SYSCTL = 'y,
  SYSFS = 'y,
  DEVTMPFS = 'y,
  DEVTMPFS_MOUNT = 'y,
  TMPFS = 'y,
  TMPFS_POSIX_ACL = 'y,
  OVERLAY_FS = 'y,
  EROFS_FS = 'y,

  # Local build tag.
  LOCALVERSION = "-bobr-tiny",
}
