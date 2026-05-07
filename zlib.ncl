let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zlib_src = {
    name = "zlib-src-1.3.1",
    tag = "Source",
    object_hash = "d916134715c36c4535c9a83759f6d48bcbf0aeed3ef2261e929151bfbfc8033f",
    origin = {
      type = "http",
      url = "https://zlib.net/fossils/zlib-1.3.1.tar.gz",
      unpack = true,
    },
    meta = {},
  }
  in

  let zlib = {
    name = "zlib-1.3.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--libdir=/usr/lib64",
      ],
    },
    inputs = {
      image = pkgs.buildpack_deps_image,
      source = zlib_src,
    },
  }
  in

  {
    include [
      zlib_src,
      zlib,
    ],
  }
