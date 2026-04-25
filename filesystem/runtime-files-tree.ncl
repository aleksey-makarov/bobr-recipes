{
  entries = [
    {
      type = "dir",
      path = "dev",
    },
    {
      type = "file",
      path = "etc/adjtime",
      text = import "runtime-files-tree-src/etc/adjtime" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/hostname",
      text = import "runtime-files-tree-src/etc/hostname" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/hosts",
      text = import "runtime-files-tree-src/etc/hosts" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/inputrc",
      text = import "runtime-files-tree-src/etc/inputrc" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/issue",
      text = import "runtime-files-tree-src/etc/issue" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/locale.conf",
      text = import "runtime-files-tree-src/etc/locale.conf" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/profile",
      text = import "runtime-files-tree-src/etc/profile" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/shadow",
      text = import "runtime-files-tree-src/etc/shadow" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/shells",
      text = import "runtime-files-tree-src/etc/shells" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/systemd/network/10-eth-dhcp.network",
      text = import "runtime-files-tree-src/etc/systemd/network/10-eth-dhcp.network" as 'Text,
      executable = false,
    },
    {
      type = "file",
      path = "etc/vconsole.conf",
      text = import "runtime-files-tree-src/etc/vconsole.conf" as 'Text,
      executable = false,
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
