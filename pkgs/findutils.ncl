let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let findutils_src = {
    version | default = "4.10.0",
    name = "findutils-src-%{version}",
    tag = "Source",
    object_hash | default = "1387e0b67ff247d2abde998f90dfbf70c1491391a59ddfecb8ae698789f0a4f5",
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
    name = "findutils-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.findutils_src,
    },
  }
  in

  let findutils = {
    name = "findutils-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "findutils-build-rootfs" [],
      source = pkgs.findutils_src,
    },
  }
  in

  {
    include [
      findutils_src,
      findutils_gen1,
      findutils,
    ],
  }
