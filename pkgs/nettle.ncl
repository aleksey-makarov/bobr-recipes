# nettle -- low-level cryptographic library (libnettle + libhogweed). The
# crypto backend GnuTLS builds on. Autotools; libhogweed needs GMP. The 3.10
# series is the one GnuTLS 3.8.x targets.
# Configure version and hash through `pkgs.nettle_src`.
fun pkgs =>
  let nettle_src = {
    version | default = "3.10.2",
    name = "nettle-src-%{version}",
    tag = "Source",
    object_hash | default = "fe9ff51cb1f2abb5e65a6b8c10a92da0ab5ab6eaf26e7fc2b675c45f1fb519b5",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/nettle/nettle-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/nettle/nettle-%{version}.tar.gz",
      ],
    },
  }
  in

  let nettle = {
    name = "nettle-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.gmp,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gmp,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
        "--disable-documentation",
      ],
    },
    inputs = {
      source = pkgs.nettle_src,
    },
  }
  in

  {
    include [
      nettle_src,
      nettle
    ]
  }
