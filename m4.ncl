let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let m4_src = {
    name = "m4-src-1.4.20",
    tag = "Source",
    object_hash = "e236ea3a1ccf5f6c270b1c4bb60726f371fa49459a8eaaebc90b216b328daf2b",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.xz",
        "https://mirrors.kernel.org/gnu/m4/m4-1.4.20.tar.xz",
      ],
    },
  }
  in

  let m4_gen1 = {
    name = "m4-gen1-1.4.20",
    tag = "AutotoolsRootfs",
    config = {},
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = m4_src,
    },
  }
  in

  let m4 = {
    name = "m4-1.4.20",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {},
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = m4_src,
    },
  }
  in

  {
    include [
      m4_gen1,
      m4,
    ],
  }
