let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let bc_src = {
    version | default = "7.0.3",
    name = "bc-src-%{version}",
    tag = "Source",
    object_hash | default = "91eb74caed0ee6655b669711a4f350c25579778694df248e28363318e03c7fc4",
    origin = {
      tag = "Http",
      url = "https://github.com/gavinhoward/bc/releases/download/%{version}/bc-%{version}.tar.xz",
    },
  }
  in

  let bc = {
    name = "bc-%{inputs.source.version}",
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
      source = pkgs.bc_src,
    },
  }
  in

  {
    include [
      bc,
      bc_src,
    ],
  }
