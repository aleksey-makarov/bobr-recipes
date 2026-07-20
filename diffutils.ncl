let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let diffutils_src = fun version => fun hash => {
    name = "diffutils-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-%{version}.tar.xz",
      ],
    },
  }
  in

  let diffutils_gen1 = {
    version | default = "3.12",
    source_object_hash | default = "7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd",
    name = "diffutils-gen1-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = diffutils_src version source_object_hash,
    },
  }
  in

  let diffutils = {
    version | default = "3.12",
    source_object_hash | default = "7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd",
    name = "diffutils-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "diffutils-build-rootfs" [],
      source = diffutils_src version source_object_hash,
    },
  }
  in

  {
    include [
      diffutils_gen1,
      diffutils,
    ],
  }
