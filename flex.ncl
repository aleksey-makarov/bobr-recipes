let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let flex_src = {
    name = "flex-src-2.6.4",
    tag = "Source",
    object_hash = "55aaa592f5879374928227b3c2de5e0b40b359db9f3959189aadc6bedd3698ed",
    origin = {
      tag = "Http",
      url = "https://github.com/westes/flex/releases/download/v2.6.4/flex-2.6.4.tar.gz",
    },
  }
  in

  let flex = {
    name = "flex-2.6.4",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.m4,
      ],
    },
    config = {
      configure_args = [
        "--disable-nls",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = flex_src,
    },
  }
  in

  {
    include [
      flex,
    ],
  }
