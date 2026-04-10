let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let diffutils_src =
    recipe.fetch "diffutils-src-3.12" {
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-3.12.tar.xz",
      ],
      hash = "md5:d1b18b20868fb561f77861cd90b05de4",
    }
  in

  let diffutils_gen1 =
    recipe.binary "diffutils-gen1-3.12" {
      script_config = {
        configure_args = ["--disable-nls"],
        env = { gl_cv_func_strcasecmp_works = "y" },
      },
    } pkgs.host_image pkgs.buildscript_autotools [diffutils_src]
  in

  let diffutils =
    recipe.binary "diffutils-3.12" {
      script_config = {
        configure_args = ["--disable-nls"],
        env = { gl_cv_func_strcasecmp_works = "y" },
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [diffutils_src]
  in

  {
    include [
      diffutils_src,
      diffutils_gen1,
      diffutils,
    ],
  }
