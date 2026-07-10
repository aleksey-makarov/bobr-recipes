let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bison_src = {
    name = "bison-src-3.8.2",
    tag = "Source",
    object_hash = "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-3.8.2.tar.xz",
      ],
    },
  }
  in

  let bison_gen1 = {
    name = "bison-gen1-3.8.2",
    tag = "AutotoolsRootfs",
    config = {},
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = bison_src,
    },
  }
  in

  let bison = {
    name = "bison-3.8.2",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.m4,
      ],
    },
    config = {},
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = bison_src,
    },
  }
  in

  {
    include [
      bison_gen1,
      bison,
    ],
  }
