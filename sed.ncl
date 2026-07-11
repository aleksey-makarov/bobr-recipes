let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let sed_src = fun version => fun hash => {
    name = "sed-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "4.9",
    source_object_hash | default = "6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181",
    name = "sed-gen1-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = sed_src version source_object_hash,
    },
  }
  in

  let sed = {
    version | default = "4.9",
    source_object_hash | default = "6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181",
    name = "sed-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = sed_src version source_object_hash,
    },
  }
  in

  {
    include [
      sed_gen1,
      sed,
    ],
  }
