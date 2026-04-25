let recipe = import "../recipe-lib.ncl" in
let tree_data = import "base-filesystem-tree.ncl" in

fun _pkgs =>
  let base_filesystem = {
    name = "base-filesystem",
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
      base_filesystem,
    ],
  }
