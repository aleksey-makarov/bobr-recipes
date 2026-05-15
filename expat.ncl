let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let expat_src = {
    name = "expat-src-2.7.1",
    tag = "Source",
    object_hash = "abdbb1ff22e063a4fafeebf73a0f250ea166a52cd264d557ef25a13cc93cd9bf",
    origin = {
      type = "http",
      url = "https://github.com/libexpat/libexpat/releases/download/R_2_7_1/expat-2.7.1.tar.xz",
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
      rootfs = pkgs.system_rootfs_2,
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
