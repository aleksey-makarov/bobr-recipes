let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let make_src = {
    name = "make-src-4.4.1",
    tag = "Source",
    object_hash = "8fe22ea52de2f8b5a65902fc322dc947f1b472f73cd7c7198c2a639e79c6d4a6",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
        "https://mirrors.kernel.org/gnu/make/make-4.4.1.tar.gz",
      ],
    },
    meta = {},
  }
  in

  let make_gen1 = {
    name = "make-gen1-4.4.1",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = make_src,
    },
  }
  in

  let make = {
    name = "make-4.4.1",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_1,
      source = make_src,
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
