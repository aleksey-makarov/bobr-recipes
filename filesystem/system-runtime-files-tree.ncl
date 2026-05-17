{
  entries = [
    {
      type = "symlink",
      path = "bin",
      target = "usr/bin",
    },
    {
      type = "dir",
      path = "dev",
    },
    {
      type = "file",
      path = "etc/adjtime",
      text = import "system-runtime-files-tree-src/etc/adjtime" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/environment",
      text = import "system-runtime-files-tree-src/etc/environment" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/fstab",
      text = import "system-runtime-files-tree-src/etc/fstab" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/group",
      text = import "system-runtime-files-tree-src/etc/group" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/hostname",
      text = import "system-runtime-files-tree-src/etc/hostname" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/hosts",
      text = import "system-runtime-files-tree-src/etc/hosts" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/inputrc",
      text = import "system-runtime-files-tree-src/etc/inputrc" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/issue",
      text = import "system-runtime-files-tree-src/etc/issue" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/ld.so.conf",
      text = import "system-runtime-files-tree-src/etc/ld.so.conf" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/locale.conf",
      text = import "system-runtime-files-tree-src/etc/locale.conf" as 'Text,
      executable = false,
    },
    {
      type = "symlink",
      path = "etc/mtab",
      target = "/proc/self/mounts",
    },
    {
      type = "file",
      path = "etc/passwd",
      text = import "system-runtime-files-tree-src/etc/passwd" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/profile",
      text = import "system-runtime-files-tree-src/etc/profile" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/shadow",
      text = import "system-runtime-files-tree-src/etc/shadow" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/shells",
      text = import "system-runtime-files-tree-src/etc/shells" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/systemd/network/10-eth-dhcp.network",
      text = import "system-runtime-files-tree-src/etc/systemd/network/10-eth-dhcp.network" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/vconsole.conf",
      text = import "system-runtime-files-tree-src/etc/vconsole.conf" as 'Text,
      executable = false,
    },
    {
      type = "dir",
      path = "home",
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
      type = "symlink",
      path = "sbin",
      target = "usr/sbin",
    },
    {
      type = "dir",
      path = "sys",
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
      path = "usr/include",
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
      path = "usr/libexec",
    },
    {
      type = "dir",
      path = "usr/sbin",
    },
    {
      type = "dir",
      path = "usr/share",
    },
    {
      type = "dir",
      path = "var/lib/systemd",
    },
    {
      type = "symlink",
      path = "var/lock",
      target = "../run/lock",
    },
    {
      type = "dir",
      path = "var/log",
    },
    {
      type = "dir",
      path = "var/mail",
    },
    {
      type = "symlink",
      path = "var/run",
      target = "../run",
    },
    {
      type = "dir",
      path = "var/spool",
    },
    {
      type = "dir",
      path = "var/tmp",
    },
  ],
}
