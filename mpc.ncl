let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpc_src = {
    name = "mpc-src-1.3.1",
    tag = "Source",
    object_hash = "ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz",
        "https://mirrors.kernel.org/gnu/mpc/mpc-1.3.1.tar.gz",
      ],
    },
  }
  in

  let mpc = {
    name = "mpc-1.3.1",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gmp,
        pkgs.mpfr,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gmp,
        pkgs.mpfr,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/mpc-1.3.1",
      ],
    },
    inputs = {
      source = mpc_src,
    },
  }
  in

  {
    include [
      mpc,
    ],
  }
