let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let lz4_src =
    {
      name = "lz4-src-1.10.0",
      tag = "Fetch",
      config = {
      url = "https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz",
      hash = "md5:dead9f5f1966d9ae56e1e32761e4e675",
      },
      inputs = {},
    }
  in

  let lz4 =
    recipe.binary "lz4-1.10.0" {
      script_config = {
        make_args = [
          "BUILD_STATIC=no",
          "PREFIX=/usr",
        ],
      },
    } pkgs.system_image_2 pkgs.buildscript_gnu_make [lz4_src]
  in

  {
    include [
      lz4_src,
      lz4,
    ],
  }
