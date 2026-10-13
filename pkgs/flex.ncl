let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let flex_src = {
    version | default = "2.6.4",
    name = "flex-src-%{version}",
    tag = "Source",
    object_hash | default = "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995",
    origin = {
      tag = "Http",
      url = "https://github.com/westes/flex/releases/download/v%{version}/flex-%{version}.tar.gz",
    },
  }
  in

  let flex = {
    name = "flex-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
        pkgs.m4,
      ],
    },
    config = {
      configure_args = [
        "--disable-nls",
      ],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "flex-build-rootfs" [],
      source = pkgs.flex_src,
    },
  }
  in

  {
    include [
      flex_src,
      flex,
    ],
  }
