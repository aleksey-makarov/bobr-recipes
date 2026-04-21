let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let diffutils_src = {
    name = "diffutils-src-3.12",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-3.12.tar.xz",
      ],
      hash = "md5:d1b18b20868fb561f77861cd90b05de4",
    },
    inputs = {},
  }
  in

  let diffutils_gen1 = {
    name = "diffutils-gen1-3.12",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      image = pkgs.host_image,
      source = diffutils_src,
    },
  }
  in

  let diffutils =
    recipe.binary
      "diffutils-3.12"
      {
        script_config = {
          configure_args = ["--disable-nls"],
          env = { gl_cv_func_strcasecmp_works = "y" },
        },
      }
      pkgs.system_image_1
      pkgs.buildscript_autotools
      [diffutils_src]
  in

  {
    include [
      diffutils_src,
      diffutils_gen1,
      diffutils,
    ],
  }
