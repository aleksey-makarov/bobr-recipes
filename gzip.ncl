let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gzip_src = {
    name = "gzip-src-1.14",
    tag = "Source",
    object_hash = "a009c1099d792fae2a9854734d7297a5d50f86c184cf7e81c5fdc90b3d31038c",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.xz",
        "https://mirrors.kernel.org/gnu/gzip/gzip-1.14.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let gzip_gen1 = {
    name = "gzip-gen1-1.14",
    tag = "AutotoolsSandbox",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = gzip_src,
    },
  }
  in

  let gzip = {
    name = "gzip-1.14",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      image = pkgs.system_image_1,
      source = gzip_src,
    },
  }
  in

  {
    include [
      gzip_src,
      gzip_gen1,
      gzip,
    ],
  }
