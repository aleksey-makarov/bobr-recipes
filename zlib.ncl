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

  let zlib =
    recipe.binary
      "zlib-1.3.1"
      {
        script_config = {
          configure_args = [
            "--libdir=/usr/lib64",
          ],
        },
      }
      pkgs.host_image
      pkgs.buildscript_autotools
      [zlib_src]
  in

  {
    include [
      zlib_src,
      zlib,
    ],
  }
