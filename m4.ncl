let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let m4_src = fun version => fun hash => {
    name = "m4-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "1.4.20",
    source_object_hash | default = "e236ea3a1ccf5f6c270b1c4bb60726f371fa49459a8eaaebc90b216b328daf2b",
    name = "m4-gen1-%{version}",
    tag = "AutotoolsStageRootfs",
    config = {},
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = m4_src version source_object_hash,
    },
  }
  in

  let m4 = {
    version | default = "1.4.20",
    source_object_hash | default = "e236ea3a1ccf5f6c270b1c4bb60726f371fa49459a8eaaebc90b216b328daf2b",
    name = "m4-%{version}",
    tag = "AutotoolsStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {},
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "m4-build-rootfs" [],
      source = m4_src version source_object_hash,
    },
  }
  in

  {
    include [
      m4_gen1,
      m4,
    ],
  }
