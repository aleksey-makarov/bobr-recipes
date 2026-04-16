let recipe = import "../recipe-lib.ncl" in
let tree_data = import "runtime-files-tree.ncl" in

fun _pkgs =>
  let qemu_runtime_files =
    recipe.tree "qemu-runtime-files" {
      tree = tree_data,
      install = {
        rules = [
          recipe.install.root_default_rule,
        ],
      },
    }
  in

  {
    include [
      qemu_runtime_files,
    ],
  }
