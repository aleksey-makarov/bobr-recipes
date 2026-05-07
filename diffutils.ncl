let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let diffutils_src = {
    name = "diffutils-src-3.12",
    tag = "Source",
    object_hash = "b25f86cc6065a6fa173176105f4fb5999514d05ba1672ce56fe431944549a53a",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-3.12.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
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
      image = pkgs.buildpack_deps_image,
      source = diffutils_src,
    },
  }
  in

  let diffutils = {
    name = "diffutils-3.12",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      image = pkgs.system_image_1,
      source = diffutils_src,
    },
  }
  in

  {
    include [
      diffutils_src,
      diffutils_gen1,
      diffutils,
    ],
  }
