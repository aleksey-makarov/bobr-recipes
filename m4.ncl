let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let m4_src = {
    name = "m4-src-1.4.20",
    tag = "Source",
    object_hash = "548c7869cf48b65967f41c44132f1c5c0d8b4eb484dccac7e18a62959f4d322a",
    origin = {
      type = "http",
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
      rootfs = pkgs.buildpack_deps_rootfs,
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
      rootfs = pkgs.system_rootfs_1,
      source = m4_src,
    },
  }
  in

  {
    include [
      m4_src,
      m4_gen1,
      m4,
    ],
  }
