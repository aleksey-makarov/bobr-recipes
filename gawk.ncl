let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gawk_src = {
    name = "gawk-src-5.3.2",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz",
        "https://mirrors.kernel.org/gnu/gawk/gawk-5.3.2.tar.xz",
      ],
      hash = "md5:b7014650c5f45e5d4837c31209dc0037",
    },
    inputs = {},
  }
  in

  let gawk_gen1 = {
    name = "gawk-gen1-5.3.2",
    tag = "Autotools",
    config = {
      configure_args = ["--without-readline"],
      pre_configure = {
        name = "prepare_source",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i 's/extras//' Makefile.in",
        ],
      },
    },
    inputs = {
      image = pkgs.host_image,
      source = gawk_src,
    },
  }
  in

  let gawk =
    recipe.binary
      "gawk-5.3.2"
      {
        script_config = {
          pre_configure = "sed -i 's/extras//' Makefile.in",
          configure_args = ["--without-readline"],
        },
      }
      pkgs.system_image_1
      pkgs.buildscript_autotools
      [gawk_src]
  in

  {
    include [
      gawk_src,
      gawk_gen1,
      gawk,
    ],
  }
