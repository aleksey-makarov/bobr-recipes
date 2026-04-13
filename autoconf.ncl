let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let autoconf_src =
    recipe.fetch "autoconf-src-2.72" {
      url = [
        "https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz",
        "https://mirrors.kernel.org/gnu/autoconf/autoconf-2.72.tar.xz",
      ],
      hash = "md5:1be79f7106ab6767f18391c5e22be701",
    }
  in

  let autoconf_build_image =
    recipe.image "autoconf-build-image" {} pkgs.system_image_2 [
      pkgs.perl,
      pkgs.inetutils,
    ]
  in

  let autoconf =
    recipe.binary "autoconf-2.72" {
      script_config = {},
    } autoconf_build_image pkgs.buildscript_autotools [autoconf_src]
  in

  {
    include [
      autoconf_src,
      autoconf,
    ],
  }
