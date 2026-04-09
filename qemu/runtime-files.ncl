let recipe = import "../recipe-lib.ncl" in
let tree_data = import "runtime-files-tree.ncl" in

fun _pkgs =>
  let qemu_runtime_files =
    recipe.tree "qemu-runtime-files" {
      tree = tree_data,
      install = {
        owners = [
          { path = "**", uid = 0, gid = 0 },
        ],
      },
    }
  in

  {
    include [
      qemu_runtime_files,
    ],
  }
