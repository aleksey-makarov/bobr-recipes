let recipe = import "../recipe-lib.ncl" in
let tree_data = import "runtime-files-tree.ncl" in

fun _pkgs =>
  let qemu_runtime_files = {
    name = "qemu-runtime-files",
    tag = "Tree",
    config = {
      tree = tree_data,
      install = {
        rules = [
          recipe.install.root_default_rule,
        ],
      },
    },
    inputs = {},
  }
  in

  {
    include [
      qemu_runtime_files,
    ],
  }
