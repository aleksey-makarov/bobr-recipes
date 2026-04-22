let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expat_src = {
    name = "expat-src-2.7.1",
    tag = "Fetch",
    config = {
      url = "https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz",
      hash = "md5:9f0c266ff4b9720beae0c6bd53ae4469",
    },
    inputs = {},
  }
  in

  let expat = {
    name = "expat-2.7.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/expat-2.7.1",
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      source = expat_src,
    },
  }
  in

  {
    include [
      expat_src,
      expat,
    ],
  }
