# GnuTLS -- TLS library. A mandatory dependency of Samba (>= 3.4.7). Autotools
# build on nettle + GMP, using the system libtasn1 and libunistring rather than
# the bundled copies, with p11-kit for PKCS#11. IDN (libidn2), the documentation,
# the test suite and the Guile bindings are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let series = fun v => std.string.join "." (std.array.slice 0 2 (std.string.split "." v)) in

  let gnutls_src = fun version =>
    fun hash =>
      {
        name = "gnutls-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.gnupg.org/ftp/gcrypt/gnutls/v%{series version}/gnutls-%{version}.tar.xz",
        },
      }
  in

  let gnutls = {
    version | default = "3.8.13",
    source_object_hash
      | default
      = "ffed8ec1bf09c2426d4f14aae377de4753b53e537d685e604e99a8b16ca9c97e",
    name = "gnutls-%{version}",
    tag = "AutotoolsInstall",
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
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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
      source = gnutls_src version source_object_hash,
    },
  }
  in

  { include [ gnutls ] }
