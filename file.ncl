let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let file_src = {
    name = "file-src-5.46",
    tag = "Source",
    object_hash = "c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088",
    origin = {
      tag = "Http",
      url = "https://astron.com/pub/file/file-5.46.tar.gz",
    },
  }
  in

  let file_build_rootfs = {
    name = "file-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.bzip2,
      ],
  }
  in

  let file = {
    name = "file-5.46",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [],
    },
    inputs = {
      _rootfs = file_build_rootfs,
      source = file_src,
    },
  }
  in

  {
    include [
      file,
    ],
  }
