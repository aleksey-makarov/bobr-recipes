let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let less_src = {
    name = "less-src-679",
    tag = "Source",
    object_hash = "9b68820c34fa8a0af6b0e01b74f0298bcdd40a0489c61649b47058908a153d78",
    origin = {
      tag = "Http",
      url = "https://www.greenwoodsoftware.com/less/less-679.tar.gz",
    },
  }
  in

  let less_build_rootfs = {
    name = "less-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.ncurses,
      ],
  }
  in

  let less = {
    name = "less-679",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
      ],
    },
    config = {
      configure_args = [
        "--sysconfdir=/etc",
      ],
    },
    inputs = {
      _rootfs = less_build_rootfs,
      source = less_src,
    },
  }
  in

  {
    include [
      less,
    ],
  }
