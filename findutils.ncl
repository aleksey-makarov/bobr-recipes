let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let findutils_src = fun version => fun hash => {
    name = "findutils-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-%{version}.tar.xz",
      ],
    },
  }
  in

  let findutils_gen1 = {
    version | default = "4.10.0",
    source_object_hash | default = "1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5",
    name = "findutils-gen1-%{version}",
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
      source = findutils_src version source_object_hash,
    },
  }
  in

  let findutils = {
    version | default = "4.10.0",
    source_object_hash | default = "1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5",
    name = "findutils-%{version}",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "findutils-build-rootfs" [],
      source = findutils_src version source_object_hash,
    },
  }
  in

  {
    include [
      findutils_gen1,
      findutils,
    ],
  }
