let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gzip_src = {
    name = "gzip-src-1.14",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.xz",
        "https://mirrors.kernel.org/gnu/gzip/gzip-1.14.tar.xz",
      ],
      hash = "md5:4bf5a10f287501ee8e8ebe00ef62b2c2",
    },
    inputs = {},
  }
  in

  let gzip_gen1 = {
    name = "gzip-gen1-1.14",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      image = pkgs.host_image,
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
