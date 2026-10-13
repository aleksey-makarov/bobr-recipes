let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let bison_src = {
    version | default = "3.8.2",
    name = "bison-src-%{version}",
    tag = "Source",
    object_hash | default = "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-%{version}.tar.xz",
      ],
    },
  }
  in

  let bison_gen1 = {
    name = "bison-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {},
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.bison_src,
    },
  }
  in

  let bison = {
    name = "bison-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
        pkgs.m4,
      ],
    },
    config = {},
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "bison-build-rootfs" [],
      source = pkgs.bison_src,
    },
  }
  in

  {
    include [
      bison_src,
      bison_gen1,
      bison,
    ],
  }
