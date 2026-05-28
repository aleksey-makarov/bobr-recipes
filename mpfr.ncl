let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpfr_src = {
    name = "mpfr-src-4.2.2",
    tag = "Source",
    object_hash = "e04bf6225b30a6ca872935e6f74f6a8072b898e147e97b23dad9f2d4ea758994",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
      ],
    },
  }
  in

  let mpfr = {
    name = "mpfr-4.2.2",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gmp,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gmp,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--enable-thread-safe",
        "--docdir=/usr/share/doc/mpfr-4.2.2",
      ],
    },
    inputs = {
      source = mpfr_src,
    },
  }
  in

  {
    include [
      mpfr_src,
      mpfr,
    ],
  }
