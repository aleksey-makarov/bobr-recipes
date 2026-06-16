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

  let base_filesystem_files = {
    name = "base-filesystem-files",
    tag = "TreeNew",
    config = {
      tree = tree_data,
    },
    inputs = {},
  }
  in

  let base_filesystem_new = {
    name = "base-filesystem-new",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = base_filesystem_files,
    },
  }
  in

  {
    include [
      base_filesystem,
      base_filesystem_new,
    ],
  }
