let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libpipeline_src = {
    name = "libpipeline-src-1.5.8",
    tag = "Source",
    object_hash = "3ba72e22d3e98c09f642df382f45c251a4f381d24d54f749f85ac5e9c1f49cf7",
    origin = {
      type = "http",
      url = "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz",
      unpack = true,
    },
    meta = {},
  }
  in

  let libpipeline = {
    name = "libpipeline-1.5.8",
    tag = "Autotools",
    config = {},
    inputs = {
      image = pkgs.system_image,
      source = libpipeline_src,
    },
  }
  in

  {
    include [
      libpipeline_src,
      libpipeline,
    ],
  }
