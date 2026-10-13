let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let make_src = {
    version | default = "4.4.1",
    name = "make-src-%{version}",
    tag = "Source",
    object_hash | default = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/make/make-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/make/make-%{version}.tar.gz",
      ],
    },
  }
  in

  let make_gen1 = {
    name = "make-gen1-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.oci_buildpack_deps_rootfs,
      source = pkgs.make_src,
    },
  }
  in

  let make = {
    name = "make-%{inputs.source.version}",
    tag = "AutotoolsStageRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = recipe.bootstrap_toolchain_rootfs pkgs "make-build-rootfs" [],
      source = pkgs.make_src,
    },
  }
  in

  {
    include [
      make_src,
      make_gen1,
      make,
    ],
  }
