let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let file_src = {
    name = "file-src-5.46",
    tag = "Source",
    object_hash = "cd04b661bb96d5ad89124e96e3faecda267fcfab56929da15e72c6bacdbe8312",
    origin = {
      type = "http",
      url = "https://astron.com/pub/file/file-5.46.tar.gz",
    },
    meta = {},
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
    tag = "AutotoolsSandbox",
    config = {
      configure_args = [],
    },
    inputs = {
      rootfs = file_build_rootfs,
      source = file_src,
    },
  }
  in

  {
    include [
      file_src,
      file,
    ],
  }
