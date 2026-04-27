let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let lz4_src = {
    name = "lz4-src-1.10.0",
    tag = "Source",
    object_hash = "657d5573d4decf4ab4527583c2fcc8da511d19555eec20de255070f108bf97b6",
    origin = {
      type = "http",
      url = "https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz",
      unpack = true,
    },
    meta = {},
  }
  in

  let lz4 = {
    name = "lz4-1.10.0",
    tag = "Makefile",
    config = {
      make_args = [
        "BUILD_STATIC=no",
        "PREFIX=/usr",
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      source = lz4_src,
    },
  }
  in

  {
    include [
      lz4_src,
      lz4,
    ],
  }
