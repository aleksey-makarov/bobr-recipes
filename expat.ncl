let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expat_src =
    recipe.fetch "expat-src-2.7.1" {
      url = "https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz",
      hash = "md5:9f0c266ff4b9720beae0c6bd53ae4469",
    }
  in

  let expat =
    recipe.binary "expat-2.7.1" {
      script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/expat-2.7.1",
        ],
      },
    } pkgs.system_image_2 pkgs.buildscript_autotools [expat_src]
  in

  {
    include [
      expat_src,
      expat,
    ],
  }
