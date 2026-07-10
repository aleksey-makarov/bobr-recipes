let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zlib_src = {
    name = "zlib-src-1.3.1",
    tag = "Source",
    object_hash = "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23",
    origin = {
      tag = "Http",
      url = "https://zlib.net/fossils/zlib-1.3.1.tar.gz",
    },
  }
  in

  let zlib = {
    name = "zlib-1.3.1",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib64",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = zlib_src,
    },
  }
  in

  {
    include [
      zlib,
    ],
  }
