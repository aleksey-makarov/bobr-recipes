let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let flex_src = fun version => fun hash => {
    name = "flex-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/westes/flex/releases/download/v%{version}/flex-%{version}.tar.gz",
    },
  }
  in

  let flex = {
    version | default = "2.6.4",
    source_object_hash | default = "e87aae032bf07c26f85ac0ed3250998c37621d95f8bd748b31f15b33c45ee995",
    name = "flex-%{version}",
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
      source = flex_src version source_object_hash,
    },
  }
  in

  {
    include [
      flex,
    ],
  }
