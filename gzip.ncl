let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gzip_src = {
    name = "gzip-src-1.14",
    tag = "Source",
    object_hash = "8c091a9bc716af4d0c6eac50d3466bd6cafa7534099368dc5c74d7b2cced3fb6",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.xz",
        "https://mirrors.kernel.org/gnu/gzip/gzip-1.14.tar.xz",
      ],
    },
  }
  in

  let gzip_gen1 = {
    name = "gzip-gen1-1.14",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = gzip_src,
    },
  }
  in

  let gzip = {
    name = "gzip-1.14",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_1,
      source = gzip_src,
    },
  }
  in

  {
    include [
      gzip_gen1,
      gzip,
    ],
  }
