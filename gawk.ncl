let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gawk_src = {
    name = "gawk-src-5.3.2",
    tag = "Source",
    object_hash = "6c94095ba63575383478eab9fae4dcffd400747f99242f8a9eec5fb7e07722ef",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz",
        "https://mirrors.kernel.org/gnu/gawk/gawk-5.3.2.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
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
      image = pkgs.buildpack_deps_image,
      source = gawk_src,
    },
  }
  in

  let gawk = {
    name = "gawk-5.3.2",
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
      image = pkgs.system_image_1,
      source = gawk_src,
    },
  }
  in

  {
    include [
      gawk_src,
      gawk_gen1,
      gawk,
    ],
  }
