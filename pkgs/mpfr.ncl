fun pkgs =>
  # Configure version and hash through pkgs.mpfr_src.
  let mpfr_src = {
    version | default = "4.2.2",
    name = "mpfr-src-%{version}",
    tag = "Source",
    object_hash | default = "b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01",
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
    name = "mpfr-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gmp,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gmp,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--enable-thread-safe",
        "--docdir=/usr/share/doc/mpfr-%{inputs.source.version}",
      ],
    },
    inputs = {
      source = pkgs.mpfr_src,
    },
  }
  in

  {
    include [
      mpfr,
      mpfr_src,
    ],
  }
