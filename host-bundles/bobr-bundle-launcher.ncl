let recipe = import "../recipe-lib.ncl" in
let local = import "bobr-bundle-launcher-local.ncl" in

# Development package for the host-built static HostBundle launcher.
#
# update-bobr-bundle-launcher.sh builds the binary, stages the fixed package
# layout, and rewrites `local` with the staging path and its content hash.
let source = {
  name = "bobr-bundle-launcher-dev-source",
  tag = "Source",
  object_hash = local.source_object_hash,
  origin = {
    tag = "Path",
    path = local.source_path,
  },
}
in

{
  name = "bobr-bundle-launcher-host-x86-64",
  tag = "FsTreeImport",
  config = {
    install = {
      rules = [
        recipe.install.fs_tree_root_default_rule,
      ],
    },
  },
  inputs = {
    input = source,
  },
}
