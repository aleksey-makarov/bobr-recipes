let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let initrd_files_files = {
    name = "initrd-files-files",
    tag = "Tree",
    config = {
      tree = {
        entries = [
          {
            type = "symlink",
            path = "init",
            target = "usr/lib/systemd/systemd",
          },
          {
            type = "symlink",
            path = "bin",
            target = "usr/bin",
          },
          {
            type = "symlink",
            path = "sbin",
            target = "usr/bin",
          },
          {
            type = "symlink",
            path = "lib",
            target = "usr/lib",
          },
          {
            type = "symlink",
            path = "lib64",
            target = "usr/lib64",
          },
          {
            type = "dir",
            path = "dev",
          },
          {
            type = "dir",
            path = "etc",
          },
          {
            type = "file",
            path = "etc/group",
            text = "root:x:0:\nnobody:x:65534:\n",
            executable = false,
          },
          {
            type = "file",
            path = "etc/initrd-release",
            text = "NAME=\"bobr initrd\"\nID=bobr-initrd\nVERSION_ID=1\n",
            executable = false,
          },
          {
            type = "symlink",
            path = "etc/mtab",
            target = "/proc/self/mounts",
          },
          {
            type = "symlink",
            path = "etc/os-release",
            target = "initrd-release",
          },
          {
            type = "file",
            path = "etc/passwd",
            text = "root:x:0:0:root:/root:/usr/bin/false\nnobody:x:65534:65534:nobody:/nonexistent:/usr/bin/false\n",
            executable = false,
          },
          {
            type = "dir",
            path = "proc",
          },
          {
            type = "dir",
            path = "root",
          },
          {
            type = "dir",
            path = "run",
          },
          {
            type = "dir",
            path = "sys",
          },
          {
            type = "dir",
            path = "sysroot",
          },
          {
            type = "dir",
            path = "tmp",
          },
          {
            type = "dir",
            path = "usr/bin",
          },
          {
            type = "dir",
            path = "usr/lib",
          },
          {
            type = "dir",
            path = "usr/lib64",
          },
          {
            type = "dir",
            path = "usr/lib/systemd/system/sysinit.target.wants",
          },
          {
            type = "dir",
            path = "usr/lib/systemd/system/sockets.target.wants",
          },
          {
            type = "dir",
            path = "usr/lib/udev/rules.d",
          },
          {
            type = "symlink",
            path = "usr/sbin",
            target = "bin",
          },
          {
            type = "dir",
            path = "var/lib/systemd",
          },
          {
            type = "dir",
            path = "var/log",
          },
          {
            type = "file",
            path = "usr/lib/udev/rules.d/99-systemd-minimal.rules",
            text = "SUBSYSTEM==\"block\", TAG+=\"systemd\"\n",
            executable = false,
          },
          {
            type = "symlink",
            path = "usr/lib/systemd/system/sysinit.target.wants/systemd-udevd.service",
            target = "../systemd-udevd.service",
          },
          {
            type = "symlink",
            path = "usr/lib/systemd/system/sysinit.target.wants/systemd-udev-trigger.service",
            target = "../systemd-udev-trigger.service",
          },
          {
            type = "symlink",
            path = "usr/lib/systemd/system/sockets.target.wants/systemd-udevd-control.socket",
            target = "../systemd-udevd-control.socket",
          },
          {
            type = "symlink",
            path = "usr/lib/systemd/system/sockets.target.wants/systemd-udevd-kernel.socket",
            target = "../systemd-udevd-kernel.socket",
          },
          {
            type = "symlink",
            path = "usr/lib/systemd/system/sockets.target.wants/systemd-udevd-varlink.socket",
            target = "../systemd-udevd-varlink.socket",
          },
        ],
      },
    },
    inputs = {},
  }
  in

  let initrd_files = {
    name = "initrd-files",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = initrd_files_files,
    },
  }
  in

  let initrd_systemd = {
    name = "initrd-systemd",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.openssl_libs,
      ],
    },
    config = {
      include = [
        "usr/bin/systemctl",
        "usr/bin/udevadm",
        "usr/lib/systemd/libsystemd-core-*.so",
        "usr/lib/systemd/libsystemd-shared-*.so",
        "usr/lib/systemd/systemd",
        "usr/lib/systemd/systemd-executor",
        "usr/lib/systemd/systemd-sysroot-fstab-check",
        "usr/lib/systemd/systemd-udevd",
        "usr/lib/systemd/systemd-volatile-root",
        "usr/lib/systemd/system-generators/systemd-fstab-generator",
        "usr/lib/systemd/system/basic.target",
        "usr/lib/systemd/system/initrd-cleanup.service",
        "usr/lib/systemd/system/initrd-fs.target",
        "usr/lib/systemd/system/initrd-parse-etc.service",
        "usr/lib/systemd/system/initrd-root-device.target",
        "usr/lib/systemd/system/initrd-root-fs.target",
        "usr/lib/systemd/system/initrd-switch-root.service",
        "usr/lib/systemd/system/initrd-switch-root.target",
        "usr/lib/systemd/system/initrd-udevadm-cleanup-db.service",
        "usr/lib/systemd/system/initrd-usr-fs.target",
        "usr/lib/systemd/system/initrd.target",
        "usr/lib/systemd/system/local-fs-pre.target",
        "usr/lib/systemd/system/local-fs.target",
        "usr/lib/systemd/system/paths.target",
        "usr/lib/systemd/system/shutdown.target",
        "usr/lib/systemd/system/slices.target",
        "usr/lib/systemd/system/sockets.target",
        "usr/lib/systemd/system/soft-reboot.target",
        "usr/lib/systemd/system/swap.target",
        "usr/lib/systemd/system/sysinit.target",
        "usr/lib/systemd/system/systemd-udev-load-credentials.service",
        "usr/lib/systemd/system/systemd-udev-trigger.service",
        "usr/lib/systemd/system/systemd-udevd-control.socket",
        "usr/lib/systemd/system/systemd-udevd-kernel.socket",
        "usr/lib/systemd/system/systemd-udevd-varlink.socket",
        "usr/lib/systemd/system/systemd-udevd.service",
        "usr/lib/systemd/system/systemd-volatile-root.service",
        "usr/lib/systemd/system/timers.target",
        "usr/lib/systemd/system/tmp.mount",
      ],
    },
    inputs = {
      tree = pkgs.systemd,
    },
  }
  in

  let initrd_kmod = {
    name = "initrd-kmod",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.openssl_libs,
        pkgs.xz_libs,
        pkgs.zstd,
        pkgs.zlib,
      ],
    },
    config = {
      include = [
        "usr/bin/kmod",
        "usr/lib64/libkmod.so*",
        "usr/bin/depmod",
        "usr/bin/insmod",
        "usr/bin/lsmod",
        "usr/bin/modinfo",
        "usr/bin/modprobe",
        "usr/bin/rmmod",
      ],
    },
    inputs = {
      tree = pkgs.kmod,
    },
  }
  in

  let initrd_util_linux = {
    name = "initrd-util-linux",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      include = [
        "usr/bin/mount",
        "usr/bin/umount",
        "usr/lib/libblkid.so*",
        "usr/lib/libmount.so*",
      ],
    },
    inputs = {
      tree = pkgs.util_linux,
    },
  }
  in

  let initrd_glibc = {
    name = "initrd-glibc",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [],
    },
    config = {
      include = [
        "usr/lib64/ld-linux-x86-64.so.2",
        "usr/lib64/libc.so.6",
        "usr/lib64/libm.so.6",
      ],
    },
    inputs = {
      tree = pkgs.glibc_libs,
    },
  }
  in

  let initrd_openssl = {
    name = "initrd-openssl",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      include = [
        "usr/lib/libcrypto.so*",
      ],
    },
    inputs = {
      tree = pkgs.openssl_libs,
    },
  }
  in

  let initrd_xz = {
    name = "initrd-xz",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      include = [
        "usr/lib/liblzma.so*",
      ],
    },
    inputs = {
      tree = pkgs.xz_libs,
    },
  }
  in

  let initrd_zstd = {
    name = "initrd-zstd",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      include = [
        "usr/lib/libzstd.so*",
      ],
    },
    inputs = {
      tree = pkgs.zstd,
    },
  }
  in

  let initrd_zlib = {
    name = "initrd-zlib",
    tag = "TreeSubset",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      include = [
        "usr/lib64/libz.so*",
      ],
    },
    inputs = {
      tree = pkgs.zlib,
    },
  }
  in

  let initrd_rootfs = {
    name = "initrd-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs = recipe.numbered_inputs [
      initrd_files,
      initrd_systemd,
      initrd_kmod,
      initrd_util_linux,
      initrd_glibc,
      initrd_openssl,
      initrd_xz,
      initrd_zstd,
      initrd_zlib,
    ],
  }
  in

  let initrd = {
    name = "initrd",
    tag = "Initramfs",
    deps = {
      build = [],
      runtime = [],
    },
    config = {},
    inputs = {
      _tree = initrd_rootfs,
    },
  }
  in

  {
    include [
      initrd_files,
      initrd_systemd,
      initrd_kmod,
      initrd_util_linux,
      initrd_glibc,
      initrd_openssl,
      initrd_xz,
      initrd_zstd,
      initrd_zlib,
      initrd_rootfs,
      initrd,
    ],
  }
