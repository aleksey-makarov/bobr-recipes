let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let diffutils_src_3_12 =
    recipe.fetch "diffutils-src-3.12" {
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-3.12.tar.xz",
      ],
      hash = "md5:d1b18b20868fb561f77861cd90b05de4",
    }
  in

  let diffutils_gen1_3_12 =
    recipe.binary "diffutils-gen1-3.12" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = ["--disable-nls"],
        env = { gl_cv_func_strcasecmp_works = "y" },
      },
    } pkgs.host_image pkgs.buildscript_autotools [diffutils_src_3_12]
  in

  let diffutils_3_12 =
    build.build_autotools {
      name = "diffutils-3.12",
      sources = [diffutils_src_3_12],
      script_config = {
        configure_args = ["--disable-nls"],
        env = { gl_cv_func_strcasecmp_works = "y" },
      },
    }
  in

  {
    include [
      diffutils_src_3_12,
      diffutils_gen1_3_12,
      diffutils_3_12,
    ],
  }
