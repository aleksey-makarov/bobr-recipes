{
  entries = [
    {
      type = "symlink",
      path = "bin",
      target = "usr/bin",
    },
    {
      type = "file",
      path = "etc/environment",
      text = import "base-filesystem-tree-src/etc/environment" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/group",
      text = import "base-filesystem-tree-src/etc/group" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/ld.so.conf",
      text = import "base-filesystem-tree-src/etc/ld.so.conf" as 'Text,
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
      text = import "base-filesystem-tree-src/etc/passwd" as 'Text,
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
      path = "var/log",
    },
    {
      type = "dir",
      path = "var/mail",
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
