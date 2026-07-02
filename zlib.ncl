let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zlib_src = {
    name = "zlib-src-1.3.1",
    tag = "Source",
    object_hash = "1cbe3faca1e06ad72608148a8451eb8bd555200216adedd8ef2417fa9c539304",
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
