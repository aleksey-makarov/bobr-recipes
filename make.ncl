let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let make_src = {
    name = "make-src-4.4.1",
    tag = "Source",
    object_hash = "88e0b8e7c89559379fd6005c7b2faa37454b6107cf1f1c447d14446a13841b0e",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
        "https://mirrors.kernel.org/gnu/make/make-4.4.1.tar.gz",
      ],
      unpack = true,
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
      image = pkgs.buildpack_deps_image,
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
      image = pkgs.system_image_1,
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
