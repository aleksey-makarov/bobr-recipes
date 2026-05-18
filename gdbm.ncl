let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gdbm_src = {
    name = "gdbm-src-1.26",
    tag = "Source",
    object_hash = "a4085e565a62f920d72da4fddb21366a05ca499bb504c37712895352bf48259a",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gdbm/gdbm-1.26.tar.gz",
        "https://mirrors.kernel.org/gnu/gdbm/gdbm-1.26.tar.gz",
      ],
    },
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
      rootfs = pkgs.system_rootfs,
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
