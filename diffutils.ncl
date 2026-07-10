let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let diffutils_src = {
    name = "diffutils-src-3.12",
    tag = "Source",
    object_hash = "7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-3.12.tar.xz",
      ],
    },
  }
  in

  let diffutils_gen1 = {
    name = "diffutils-gen1-3.12",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = diffutils_src,
    },
  }
  in

  let diffutils = {
    name = "diffutils-3.12",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = diffutils_src,
    },
  }
  in

  {
    include [
      diffutils_gen1,
      diffutils,
    ],
  }
