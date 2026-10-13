let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let sed_src = {
    version | default = "4.9",
    name = "sed-src-%{version}",
    tag = "Source",
    object_hash | default = "6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-%{version}.tar.xz",
      ],
    },
  }
  in

  let sed_gen1 = {
    name = "sed-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.sed_src,
    },
  }
  in

  let sed = {
    name = "sed-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "sed-build-rootfs" [],
      source = pkgs.sed_src,
    },
  }
  in

  {
    include [
      sed_src,
      sed_gen1,
      sed,
    ],
  }
