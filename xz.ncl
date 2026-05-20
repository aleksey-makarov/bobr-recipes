let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xz_src = {
    name = "xz-src-5.8.1",
    tag = "Source",
    object_hash = "74e8e63e33f82cd950ec6ab7a6e1d477cb0bc359772fa96b6e75d37c9364dd59",
    origin = {
      type = "http",
      url = "https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.xz",
    },
  }
  in

  let xz_gen1 = {
    name = "xz-gen1-5.8.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/xz-5.8.1",
      ],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = xz_src,
    },
  }
  in

  let xz = {
    name = "xz-5.8.1",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/xz-5.8.1",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_2,
      source = xz_src,
    },
  }
  in

  let xz_libs =
    recipe.split.libs xz "usr/lib/liblzma.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      xz_src,
      xz_gen1,
      xz,
      xz_libs,
    ],
  }
