let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xz_src = {
    name = "xz-src-5.8.1",
    tag = "Source",
    object_hash = "0b54f79df85912504de0b14aec7971e3f964491af1812d83447005807513cd9e",
    origin = {
      tag = "Http",
      url = "https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.xz",
    },
  }
  in

  let xz_gen1 = {
    name = "xz-gen1-5.8.1",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/xz-5.8.1",
      ],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = xz_src,
    },
  }
  in

  let xz = {
    name = "xz-5.8.1",
    tag = "AutotoolsRootfs",
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
      _rootfs = pkgs.system_rootfs_2,
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
      xz_gen1,
      xz,
      xz_libs,
    ],
  }
