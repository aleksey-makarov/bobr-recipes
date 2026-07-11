let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zlib_src = fun version => fun hash => {
    name = "zlib-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://zlib.net/fossils/zlib-%{version}.tar.gz",
    },
  }
  in

  let zlib = {
    version | default = "1.3.1",
    source_object_hash | default = "9a93b2b7dfdac77ceba5a558a580e74667dd6fede4585b91eefb60f03b72df23",
    name = "zlib-%{version}",
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
      source = zlib_src version source_object_hash,
    },
  }
  in

  {
    include [
      zlib,
    ],
  }
