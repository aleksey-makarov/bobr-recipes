let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let make_src_4_4_1 =
    recipe.fetch "make-src-4.4.1" {
      url = [
        "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
        "https://mirrors.kernel.org/gnu/make/make-4.4.1.tar.gz",
      ],
      hash = "md5:c8469a3713cbbe04d955d4ae4be23eeb",
    }
  in

  let make_gen1_4_4_1 =
    recipe.binary "make-gen1-4.4.1" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.host_image pkgs.buildscript_autotools [make_src_4_4_1]
  in

  let make_4_4_1 =
    build.build_autotools {
      name = "make-4.4.1",
      sources = [make_src_4_4_1],
      script_config = {
        configure_args = ["--disable-nls"],
      },
    }
  in

  {
    include [
      make_src_4_4_1,
      make_gen1_4_4_1,
      make_4_4_1,
    ],
  }
