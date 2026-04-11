let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let xz_src =
    recipe.fetch "xz-src-5.8.1" {
      url = "https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.xz",
      hash = "md5:cf5e1feb023d22c6bdaa30e84ef3abe3",
    }
  in

  let xz =
    build.build_autotools {
      name = "xz-5.8.1",
      sources = [xz_src],
      script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/xz-5.8.1",
        ],
      },
    }
  in

  {
    include [
      xz_src,
      xz,
    ],
  }
