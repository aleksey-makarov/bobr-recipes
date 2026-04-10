let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let expat_src =
    recipe.fetch "expat-src-2.7.1" {
      url = "https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz",
      hash = "md5:9f0c266ff4b9720beae0c6bd53ae4469",
    }
  in

  let expat =
    build.build_autotools {
      name = "expat-2.7.1",
      sources = [expat_src],
      script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/expat-2.7.1",
        ],
      },
    }
  in

  {
    include [
      expat_src,
      expat,
    ],
  }
