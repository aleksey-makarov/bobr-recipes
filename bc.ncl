let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bc_src = {
    name = "bc-src-7.0.3",
    tag = "Source",
    object_hash = "efc1df54c5378be62a93662e34f6829af1738a858211bd51c8d9b6c0892825ac",
    origin = {
      tag = "Http",
      url = "https://github.com/gavinhoward/bc/archive/c8dabac65d39fd527a9264a5e505a99b1d8df3d8.tar.gz",
    },
  }
  in

  let bc = {
    name = "bc-7.0.3",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-history",
        "--disable-man-pages",
        "--disable-nls",
      ],
      env = {
        CC = "gcc -std=c99",
        HOSTCC = "gcc -std=c99",
      },
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = bc_src,
    },
  }
  in

  {
    include [
      bc,
    ],
  }
