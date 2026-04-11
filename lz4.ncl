let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let lz4_src =
    recipe.fetch "lz4-src-1.10.0" {
      url = "https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz",
      hash = "md5:dead9f5f1966d9ae56e1e32761e4e675",
    }
  in

  let lz4 =
    build.build_make {
      name = "lz4-1.10.0",
      sources = [lz4_src],
      script_config = {
        make_args = [
          "BUILD_STATIC=no",
          "PREFIX=/usr",
        ],
      },
    }
  in

  {
    include [
      lz4_src,
      lz4,
    ],
  }
