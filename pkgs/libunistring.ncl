# libunistring -- Unicode string library. A dependency of GnuTLS (used as the
# system unistring rather than GnuTLS's bundled copy). Autotools build.
# Configure version and hash through `pkgs.libunistring_src`.
fun pkgs =>
  let libunistring_src = {
    version | default = "1.4.2",
    name = "libunistring-src-%{version}",
    tag = "Source",
    object_hash | default = "5b46e74377ed7409c5b75e7a96f95377b095623b689d8522620927964a41499c",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/libunistring/libunistring-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/libunistring/libunistring-%{version}.tar.xz",
      ],
    },
  }
  in

  let libunistring = {
    name = "libunistring-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.libunistring_src,
    },
  }
  in

  {
    include [
      libunistring_src,
      libunistring
    ]
  }
