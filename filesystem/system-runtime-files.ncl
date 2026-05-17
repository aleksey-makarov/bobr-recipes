let recipe = import "../recipe-lib.ncl" in
let tree_data = import "system-runtime-files-tree.ncl" in

fun _pkgs =>
  let system_runtime_files = {
    name = "system-runtime-files",
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
      system_runtime_files,
    ],
  }
