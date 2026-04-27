let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let file_src = {
    name = "file-src-5.46",
    tag = "Source",
    object_hash = "86dcad02a676f63c74767540161ae441ea16e77abaa1c50a6668853297a9f43b",
    origin = {
      type = "http",
      url = "https://astron.com/pub/file/file-5.46.tar.gz",
      unpack = true,
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
