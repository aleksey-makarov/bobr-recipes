let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpfr_src = {
    name = "mpfr-src-4.2.2",
    tag = "Source",
    object_hash = "b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01",
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
      mpfr,
    ],
  }
