let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bison_src = fun version => fun hash => {
    name = "bison-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "3.8.2",
    source_object_hash | default = "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2",
    name = "bison-gen1-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {},
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = bison_src version source_object_hash,
    },
  }
  in

  let bison = {
    version | default = "3.8.2",
    source_object_hash | default = "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2",
    name = "bison-%{version}",
    tag = "AutotoolsStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.m4,
      ],
    },
    config = {},
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "bison-build-rootfs" [],
      source = bison_src version source_object_hash,
    },
  }
  in

  {
    include [
      bison_gen1,
      bison,
    ],
  }
