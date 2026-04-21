let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let autoconf_src = {
    name = "autoconf-src-2.72",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/autoconf/autoconf-2.72.tar.xz",
        "https://mirrors.kernel.org/gnu/autoconf/autoconf-2.72.tar.xz",
      ],
      hash = "md5:1be79f7106ab6767f18391c5e22be701",
    },
    inputs = {},
  }
  in

  let autoconf_build_image = {
    name = "autoconf-build-image",
    tag = "Image",
    config = { ref_name | default = "autoconf-build-image" } & {},
    inputs = {
      base = pkgs.system_image_2,
      inputs = [
        pkgs.perl,
        pkgs.inetutils,
      ],
    },
  }
  in

  let autoconf =
    recipe.binary
      "autoconf-2.72"
      {
        script_config = {},
      }
      autoconf_build_image
      pkgs.buildscript_autotools
      [autoconf_src]
  in

  {
    include [
      autoconf_src,
      autoconf,
    ],
  }
