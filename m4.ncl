let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let m4_src =
    recipe.fetch "m4-src-1.4.20" {
      url = [
        "https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.xz",
        "https://mirrors.kernel.org/gnu/m4/m4-1.4.20.tar.xz",
      ],
      hash = "md5:6eb2ebed5b24e74b6e890919331d2132",
    }
  in

  let m4_gen1 =
    recipe.binary "m4-gen1-1.4.20" {
      script_config = {},
    } pkgs.host_image pkgs.buildscript_autotools [m4_src]
  in

  let m4 =
    recipe.binary "m4-1.4.20" {
      script_config = {},
    } pkgs.system_image_1 pkgs.buildscript_autotools [m4_src]
  in

  {
    include [
      m4_src,
      m4_gen1,
      m4,
    ],
  }
