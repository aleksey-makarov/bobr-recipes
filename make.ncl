let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let make_src = {
    name = "make-src-4.4.1",
    tag = "Source",
    object_hash = "dd16fb1d67bfab79a72f5e8390735c49e3e8e70b4945a15ab1f81ddb78658fb3",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
        "https://mirrors.kernel.org/gnu/make/make-4.4.1.tar.gz",
      ],
    },
  }
  in

  let make_gen1 = {
    name = "make-gen1-4.4.1",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = make_src,
    },
  }
  in

  let make = {
    name = "make-4.4.1",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = make_src,
    },
  }
  in

  {
    include [
      make_gen1,
      make,
    ],
  }
