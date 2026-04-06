{
  entries = [
    {
      type = "dir",
      path = "dev",
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
      path = "init",
      text = "#!/bin/bash\nset -euo pipefail\n\nexport PATH=/usr/bin:/usr/sbin:/bin:/sbin\nexport HOME=/root\nexport USER=root\nexport SHELL=/bin/bash\ncd /root\n\necho \"mbuild qemu rootfs booted\"\nexec /bin/bash -l\n",
      executable = true,
    },
    {
      type = "dir",
      path = "proc",
    },
    {
      type = "dir",
      path = "sys",
    },
  ],
}
