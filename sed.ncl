let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let sed_src = {
    name = "sed-src-4.9",
    tag = "Source",
    object_hash = "6e226b732e1cd739464ad6862bd1a1aba42d7982922da7a53519631d24975181",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-4.9.tar.xz",
      ],
    },
  }
  in

  let sed_gen1 = {
    name = "sed-gen1-4.9",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = sed_src,
    },
  }
  in

  let sed = {
    name = "sed-4.9",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = sed_src,
    },
  }
  in

  {
    include [
      sed_gen1,
      sed,
    ],
  }
