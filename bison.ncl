let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bison_src =
    recipe.fetch "bison-src-3.8.2" {
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-3.8.2.tar.xz",
      ],
      hash = "md5:c28f119f405a2304ff0a7ccdcc629713",
    }
  in

  let bison_gen1 =
    recipe.binary "bison-gen1-3.8.2" {
      script_config = {},
    } pkgs.host_image pkgs.buildscript_autotools [bison_src]
  in

  let bison =
    recipe.binary "bison-3.8.2" {
      script_config = {},
    } pkgs.system_image_1 pkgs.buildscript_autotools [bison_src]
  in

  {
    include [
      bison_src,
      bison_gen1,
      bison,
    ],
  }
