let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gdbm_src = {
    name = "gdbm-src-1.26",
    tag = "Source",
    object_hash = "6a24504a14de4a744103dcb936be976df6fbe88ccff26065e54c1c47946f4a5e",
    origin = {
      tag = "Http",
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
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--enable-libgdbm-compat",
      ],
    },
    inputs = {
      source = gdbm_src,
    },
  }
  in

  {
    include [
      gdbm,
    ],
  }
