let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let m4_src = {
    version | default = "1.4.20",
    name = "m4-src-%{version}",
    tag = "Source",
    object_hash | default = "e236ea3a1ccf5f6c270b1c4bb60726f371fa49459a8eaaebc90b216b328daf2b",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/m4/m4-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/m4/m4-%{version}.tar.xz",
      ],
    },
  }
  in

  let m4_gen1 = {
    name = "m4-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {},
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.m4_src,
    },
  }
  in

  let m4 = {
    name = "m4-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {},
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "m4-build-rootfs" [],
      source = pkgs.m4_src,
    },
  }
  in

  {
    include [
      m4_src,
      m4_gen1,
      m4,
    ],
  }
