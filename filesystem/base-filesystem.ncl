let recipe = import "../recipe-lib.ncl" in

fun _pkgs =>
  let base_filesystem_source = {
    name = "base-filesystem-source",
    tag = "Source",
    object_hash = import "base-filesystem.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "filesystem/base-filesystem",
    },
  }
  in

  let base_filesystem_source_import = {
    name = "base-filesystem-source-import",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = base_filesystem_source,
    },
  }
  in

  let base_filesystem_empty_dirs = {
    name = "base-filesystem-empty-dirs",
    tag = "Tree",
    config = {
      tree = {
        entries = [
          { type = "dir", path = "home" },
          { type = "dir", path = "root" },
          { type = "dir", path = "run" },
          { type = "dir", path = "tmp" },
          { type = "dir", path = "usr/bin" },
          { type = "dir", path = "usr/include" },
          { type = "dir", path = "usr/lib64" },
          { type = "dir", path = "usr/libexec" },
          { type = "dir", path = "usr/share" },
          { type = "dir", path = "var/log" },
          { type = "dir", path = "var/mail" },
          { type = "dir", path = "var/spool" },
          { type = "dir", path = "var/tmp" },
        ],
      },
    },
    inputs = {},
  }
  in

  let base_filesystem_empty_dirs_import = {
    name = "base-filesystem-empty-dirs-import",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = base_filesystem_empty_dirs,
    },
  }
  in

  let base_filesystem = {
    name = "base-filesystem",
    tag = "TreeMerge",
    config = {},
    inputs = {
      source = base_filesystem_source_import,
      empty_dirs = base_filesystem_empty_dirs_import,
    },
  }
  in

  {
    include [
      base_filesystem,
    ],
  }
