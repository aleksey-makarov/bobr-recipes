let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expat_src = {
    name = "expat-src-2.7.1",
    tag = "Source",
    object_hash = "17be589489d3ce4b1745b0ee9b87b459a63e15dda3b096f59276d0179c7cd98c",
    origin = {
      type = "http",
      url = "https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz",
      unpack = true,
    },
    meta = {},
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
