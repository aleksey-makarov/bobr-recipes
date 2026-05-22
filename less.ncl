let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let less_src = {
    name = "less-src-679",
    tag = "Source",
    object_hash = "c2b5899447db3b01823c6306d9147022865137832d46dbfb6129864e876ba9ca",
    origin = {
      type = "http",
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
      rootfs = less_build_rootfs,
      source = less_src,
    },
  }
  in

  {
    include [
      less_src,
      less,
    ],
  }
