let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bc_src = fun version => fun hash => {
    name = "bc-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/gavinhoward/bc/archive/c8dabac65d39fd527a9264a5e505a99b1d8df3d8.tar.gz",
    },
  }
  in

  let bc = {
    version | default = "7.0.3",
    source_object_hash | default = "efc1df54c5378be62a93662e34f6829af1738a858211bd51c8d9b6c0892825ac",
    name = "bc-%{version}",
    tag = "AutotoolsStageRootfs",
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
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "bc-build-rootfs" [],
      source = bc_src version source_object_hash,
    },
  }
  in

  {
    include [
      bc,
    ],
  }
