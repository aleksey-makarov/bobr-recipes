{
  entries = [
    {
      type = "dir",
      path = "dev",
    },
    {
      type = "file",
      path = "etc/hostname",
      text = import "runtime-files-tree-src/etc/hostname" as 'Text,
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
      path = "init",
      text = import "runtime-files-tree-src/init" as 'Text,
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
