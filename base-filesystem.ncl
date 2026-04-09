let recipe = import "recipe-lib.ncl" in
let tree_data = import "base-filesystem-tree.ncl" in

fun _pkgs =>
  let base_filesystem =
    recipe.tree "base-filesystem" {
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
      base_filesystem,
    ],
  }
