let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zlib_src = {
    name = "zlib-src-1.3.1",
    tag = "Fetch",
    config = {
      url = "https://zlib.net/fossils/zlib-1.3.1.tar.gz",
      hash = "md5:9855b6d802d7fe5b7bd5b196a2271655",
    },
    inputs = {},
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
      image = pkgs.host_image,
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
