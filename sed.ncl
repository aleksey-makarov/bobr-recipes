let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let sed_src = {
    name = "sed-src-4.9",
    tag = "Source",
    object_hash = "9194a87abb3243d375c349b457c16fb763275af0db65512b45b4f573a947bf32",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-4.9.tar.xz",
      ],
    },
    meta = {},
  }
  in

  let sed_gen1 = {
    name = "sed-gen1-4.9",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = sed_src,
    },
  }
  in

  let sed = {
    name = "sed-4.9",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_1,
      source = sed_src,
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
