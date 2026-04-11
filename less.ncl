let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let less_src =
    recipe.fetch "less-src-679" {
      url = "https://www.greenwoodsoftware.com/less/less-679.tar.gz",
      hash = "md5:0386dc14f6a081a94dfb4c2413864eed",
    }
  in

  let less_build_image =
    recipe.image "less-build-image" {} pkgs.system_image [
      pkgs.ncurses,
    ]
  in

  let less =
    recipe.binary "less-679" {
      script_config = {
        configure_args = [
          "--sysconfdir=/etc",
        ],
      },
    } less_build_image pkgs.buildscript_autotools [less_src]
  in

  {
    include [
      less_src,
      less,
    ],
  }
