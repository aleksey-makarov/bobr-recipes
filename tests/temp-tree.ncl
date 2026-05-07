let recipe = import "../recipe-lib.ncl" in

fun _pkgs =>
  let temp_tree_playground = {
    name = "temp-tree-playground",
    tag = "Tree",
    config = {
      tree = {
        entries = [
          {
            type = "file",
            path = "README.txt",
            text = m%"
              temporary Tree recipe
              root-owned regular file
            "%,
            executable = false,
          },
          {
            type = "dir",
            path = "bin",
          },
          {
            type = "file",
            path = "bin/run-demo",
            text = m%"
              #!/bin/sh
              echo temp-tree-demo
            "%,
            executable = true,
          },
          {
            type = "symlink",
            path = "bin/demo-conf",
            target = "../etc/demo.conf",
          },
          {
            type = "file",
            path = "etc/demo.conf",
            text = m%"
              mode = demo
              owner = root:daemon-like
            "%,
            executable = false,
          },
          {
            type = "dir",
            path = "opt/demo/share",
          },
          {
            type = "file",
            path = "opt/demo/share/info.txt",
            text = m%"
              read-only shared data
            "%,
            executable = false,
          },
          {
            type = "dir",
            path = "var/cache/demo",
          },
          {
            type = "file",
            path = "var/cache/demo/cache.txt",
            text = m%"
              cache placeholder
            "%,
            executable = false,
          },
          {
            type = "file",
            path = "var/lib/demo/state.txt",
            text = m%"
              private state
            "%,
            executable = false,
          },
          {
            type = "symlink",
            path = "var/lib/demo/current",
            target = "state.txt",
          },
        ],
      },
      install = {
        rules = [
          recipe.install.root_default_rule,
          {
            path = "bin/**",
            attrs = {
              uid = 1,
              gid = 1,
              directory_mode = 0o755,
              regular_file_mode = 0o640,
              executable_file_mode = 0o750,
              symlink_mode = 0o777,
            },
          },
          {
            path = "etc/**",
            attrs = {
              gid = 1,
              directory_mode = 0o750,
              regular_file_mode = 0o640,
              symlink_mode = 0o777,
            },
          },
          {
            path = "opt/demo/share/**",
            attrs = {
              uid = 1,
              gid = 0,
              directory_mode = 0o555,
              regular_file_mode = 0o444,
              executable_file_mode = 0o555,
              symlink_mode = 0o777,
            },
          },
          {
            path = "var/cache/demo/**",
            attrs = {
              uid = 2,
              gid = 2,
              directory_mode = 0o770,
              regular_file_mode = 0o660,
              executable_file_mode = 0o770,
              symlink_mode = 0o777,
            },
          },
          {
            path = "var/lib/demo/**",
            attrs = {
              uid = 2,
              gid = 2,
              directory_mode = 0o700,
              regular_file_mode = 0o600,
              executable_file_mode = 0o700,
              symlink_mode = 0o777,
            },
          },
        ],
      },
    },
    inputs = {},
  }
  in

  {
    include [
      temp_tree_playground,
    ],
  }
