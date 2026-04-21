let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bison_src = {
    name = "bison-src-3.8.2",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-3.8.2.tar.xz",
      ],
      hash = "md5:c28f119f405a2304ff0a7ccdcc629713",
    },
    inputs = {},
  }
  in

  let bison_gen1 = {
    name = "bison-gen1-3.8.2",
    tag = "Autotools",
    config = {},
    inputs = {
      image = pkgs.host_image,
      source = bison_src,
    },
  }
  in

  let bison =
    recipe.binary
      "bison-3.8.2"
      {
        script_config = {},
      }
      pkgs.system_image_1
      pkgs.buildscript_autotools
      [bison_src]
  in

  {
    include [
      bison_src,
      bison_gen1,
      bison,
    ],
  }
