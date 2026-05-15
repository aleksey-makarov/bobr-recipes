let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let diffutils_src = {
    name = "diffutils-src-3.12",
    tag = "Source",
    object_hash = "f4f22c6a73db50f41e0254ce32e15fb112dfbe99616eb63364196f958a6f9e3e",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-3.12.tar.xz",
      ],
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
      rootfs = pkgs.buildpack_deps_rootfs,
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
      rootfs = pkgs.system_rootfs_1,
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
