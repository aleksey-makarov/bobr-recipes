let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let findutils_src = {
    name = "findutils-src-4.10.0",
    tag = "Source",
    object_hash = "1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz",
      ],
    },
  }
  in

  let findutils_gen1 = {
    name = "findutils-gen1-4.10.0",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = findutils_src,
    },
  }
  in

  let findutils = {
    name = "findutils-4.10.0",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = findutils_src,
    },
  }
  in

  {
    include [
      findutils_gen1,
      findutils,
    ],
  }
