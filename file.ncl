let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let file_src = fun version => fun hash => {
    name = "file-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://astron.com/pub/file/file-%{version}.tar.gz",
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
    version | default = "5.46",
    source_object_hash | default = "c9cc77c7c560c543135edc555af609d5619dbef011997e988ce40a3d75d86088",
    name = "file-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [],
    },
    inputs = {
      _rootfs = file_build_rootfs,
      source = file_src version source_object_hash,
    },
  }
  in

  {
    include [
      file,
    ],
  }
