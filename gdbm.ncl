let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gdbm_src = {
    name = "gdbm-src-1.26",
    tag = "Source",
    object_hash = "633737ebb34cfe68bf9ffcd84050ba454612b421115c57803a23ed7742719914",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gdbm/gdbm-1.26.tar.gz",
        "https://mirrors.kernel.org/gnu/gdbm/gdbm-1.26.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let gdbm = {
    name = "gdbm-1.26",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--enable-libgdbm-compat",
      ],
    },
    inputs = {
      image = pkgs.system_image,
      source = gdbm_src,
    },
  }
  in

  {
    include [
      gdbm_src,
      gdbm,
    ],
  }
