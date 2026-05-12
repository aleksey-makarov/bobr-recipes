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

  let file_build_image = {
    name = "file-build-image",
    tag = "Image",
    config = { ref_name | default = "file-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.bzip2,
        pkgs.xz,
      ],
  }
  in

  let file = {
    name = "file-5.46",
    tag = "Autotools",
    config = {
      configure_args = [],
    },
    inputs = {
      image = file_build_image,
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
