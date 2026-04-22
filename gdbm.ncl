let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gdbm_src = {
    name = "gdbm-src-1.26",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/gdbm/gdbm-1.26.tar.gz",
        "https://mirrors.kernel.org/gnu/gdbm/gdbm-1.26.tar.gz",
      ],
      hash = "md5:aaa600665bc89e2febb3c7bd90679115",
    },
    inputs = {},
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
