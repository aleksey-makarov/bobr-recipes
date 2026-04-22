let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let file_src = {
    name = "file-src-5.46",
    tag = "Fetch",
    config = {
      url = "https://astron.com/pub/file/file-5.46.tar.gz",
      hash = "md5:459da2d4b534801e2e2861611d823864",
    },
    inputs = {},
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
