let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let diffutils_src = {
    version | default = "3.12",
    name = "diffutils-src-%{version}",
    tag = "Source",
    object_hash | default = "7c8b7f9fc8609141fdea9cece85249d308624391ff61dedaf528fcb337727dfd",
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
    name = "diffutils-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.diffutils_src,
    },
  }
  in

  let diffutils = {
    name = "diffutils-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "diffutils-build-rootfs" [],
      source = pkgs.diffutils_src,
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
