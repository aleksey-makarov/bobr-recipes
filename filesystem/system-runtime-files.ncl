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

  let system_runtime_files_files = {
    name = "system-runtime-files-files",
    tag = "TreeNew",
    config = {
      tree = tree_data,
    },
    inputs = {},
  }
  in

  let system_runtime_files_new = {
    name = "system-runtime-files-new",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = system_runtime_files_files,
    },
  }
  in

  {
    include [
      system_runtime_files,
      system_runtime_files_new,
    ],
  }
