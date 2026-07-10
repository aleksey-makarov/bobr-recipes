let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let flex_src = {
    name = "flex-src-2.6.4",
    tag = "Source",
    object_hash = "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995",
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
