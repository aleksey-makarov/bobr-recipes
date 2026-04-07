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
      path = "etc/group",
      text = "root:x:0:\nbin:x:1:\nsys:x:2:\nkmem:x:9:\nwheel:x:10:\nnobody:x:65534:\n",
      executable = false,
    },
    {
      type = "file",
      path = "etc/hostname",
      text = "mbuild-qemu\n",
      executable = false,
    },
    {
      type = "file",
      path = "etc/issue",
      text = "mbuild qemu rootfs\n",
      executable = false,
    },
    {
      type = "file",
      path = "etc/ld.so.conf",
      text = "/usr/lib\n/usr/lib64\n",
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
      text = "root:x:0:0:root:/root:/bin/bash\nnobody:x:65534:65534:nobody:/nonexistent:/usr/bin/false\n",
      executable = false,
    },
    {
      type = "dir",
      path = "home",
    },
    {
      type = "file",
      path = "init",
      text = "#!/bin/bash\nset -euo pipefail\n\nexport PATH=/usr/bin:/usr/sbin:/bin:/sbin\nexport HOME=/root\nexport USER=root\nexport SHELL=/bin/bash\ncd /root\n\necho \"mbuild qemu rootfs booted\"\nexec /bin/bash -l\n",
      executable = true,
    },
    {
      type = "symlink",
      path = "lib",
      target = "usr/lib",
    },
    {
      type = "dir",
      path = "lib64",
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
