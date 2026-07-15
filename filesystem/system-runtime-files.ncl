let recipe = import "../recipe-lib.ncl" in

fun _pkgs =>
  let system_runtime_files_source = {
    name = "system-runtime-files-source",
    tag = "Source",
    object_hash = import "system-runtime-files.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "filesystem/system-runtime-files",
    },
  }
  in

  let system_runtime_files_source_import = {
    name = "system-runtime-files-source-import",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = system_runtime_files_source,
    },
  }
  in

  let system_runtime_files_empty_dirs = {
    name = "system-runtime-files-empty-dirs",
    tag = "Tree",
    config = {
      tree = {
        entries = [
          { type = "dir", path = "dev" },
          { type = "dir", path = "home" },
          { type = "dir", path = "proc" },
          { type = "dir", path = "root" },
          { type = "dir", path = "run" },
          { type = "dir", path = "sys" },
          { type = "dir", path = "tmp" },
          { type = "dir", path = "usr/bin" },
          { type = "dir", path = "usr/include" },
          { type = "dir", path = "usr/lib64" },
          { type = "dir", path = "usr/libexec" },
          { type = "dir", path = "usr/share" },
          { type = "dir", path = "var/lib/systemd" },
          { type = "dir", path = "var/log" },
          { type = "dir", path = "var/mail" },
          { type = "dir", path = "var/spool" },
          { type = "dir", path = "var/tmp" },
          # Default system time zone. Requires the tzdata package (zoneinfo) in
          # the rootfs; without a named zone the calendar/ICU code paths get a
          # NULL zone.
          {
            type = "symlink",
            path = "etc/localtime",
            target = "../usr/share/zoneinfo/Europe/Berlin",
          },
        ],
      },
    },
    inputs = {},
  }
  in

  let system_runtime_files_empty_dirs_import = {
    name = "system-runtime-files-empty-dirs-import",
    tag = "FsTreeImport",
    config = {
      install = {
        rules = [
          recipe.install.fs_tree_root_default_rule,
        ],
      },
    },
    inputs = {
      input = system_runtime_files_empty_dirs,
    },
  }
  in

  let system_runtime_files = {
    name = "system-runtime-files",
    tag = "TreeMerge",
    config = {},
    inputs = {
      source = system_runtime_files_source_import,
      empty_dirs = system_runtime_files_empty_dirs_import,
    },
  }
  in

  {
    include [
      system_runtime_files,
    ],
  }
