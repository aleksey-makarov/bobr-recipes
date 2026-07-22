fun pkgs =>
  let mpfr_src = fun version => fun hash => {
    name = "mpfr-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/mpfr/mpfr-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-%{version}.tar.xz",
      ],
    },
  }
  in

  let mpfr = {
    version | default = "4.2.2",
    source_object_hash | default = "b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01",
    name = "mpfr-%{version}",
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
        "--docdir=/usr/share/doc/mpfr-%{version}",
      ],
    },
    inputs = {
      source = mpfr_src version source_object_hash,
    },
  }
  in

  {
    include [
      mpfr,
    ],
  }
