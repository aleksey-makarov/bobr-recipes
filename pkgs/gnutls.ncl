let recipe = import "../recipe-lib.ncl" in
# GnuTLS -- TLS library. A mandatory dependency of Samba (>= 3.4.7). Autotools
# build on nettle + GMP, using the system libtasn1 and libunistring rather than
# the bundled copies, with p11-kit for PKCS#11. IDN (libidn2), the documentation,
# the test suite and the Guile bindings are off.
# Configure version and hash through `pkgs.gnutls_src`.
fun pkgs =>
  let series = recipe.version_prefix 2 in

  let gnutls_src = {
    version | default = "3.8.13",
    name = "gnutls-src-%{version}",
    tag = "Source",
    object_hash | default = "ffed8ec1bf09c2426d4f14aae377de4753b53e537d685e604e99a8b16ca9c97e",
    origin = {
      tag = "Http",
      url = "https://www.gnupg.org/ftp/gcrypt/gnutls/v%{series version}/gnutls-%{version}.tar.xz",
    },
  }
  in

  let gnutls = {
    name = "gnutls-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.nettle,
        pkgs.gmp,
        pkgs.libtasn1,
        pkgs.libunistring,
        pkgs.p11_kit,
        pkgs.zlib,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
        pkgs.nettle,
        pkgs.gmp,
        pkgs.libtasn1,
        pkgs.libunistring,
        pkgs.p11_kit,
        pkgs.zlib,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
        "--disable-doc",
        "--disable-tests",
        "--disable-guile",
        "--without-idn",
        "--with-included-libtasn1=no",
        "--with-included-unistring=no",
      ],
    },
    inputs = {
      source = pkgs.gnutls_src,
    },
  }
  in

  {
    include [
      gnutls_src,
      gnutls
    ]
  }
