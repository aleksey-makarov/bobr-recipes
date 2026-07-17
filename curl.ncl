# curl -- the libcurl HTTP/transfer library. Pulled in because AppStream links
# libcurl unconditionally (for its metadata pool downloader; unused by our
# consumers, but the library must load). Autotools build against OpenSSL, using
# our existing zlib, nghttp2 (HTTP/2) and libpsl. IDN, brotli, zstd, LDAP, libssh
# and the built-in manual are off to keep the closure down.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let curl_src = fun version =>
    fun hash =>
      {
        name = "curl-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://curl.se/download/curl-%{version}.tar.xz",
        },
      }
  in

  let curl = {
    version | default = "8.16.0",
    source_object_hash
      | default
      = "40c8cddbcb6cc6251c03dea423a472a6cea4037be654ba5cf5dec6eb2d22ff1d",
    name = "curl-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.openssl,
        pkgs.zlib,
        pkgs.nghttp2,
        pkgs.libpsl,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.openssl,
        pkgs.zlib,
        pkgs.nghttp2,
        pkgs.libpsl,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--with-openssl",
        "--with-ca-bundle=/etc/ssl/certs/ca-certificates.crt",
        "--with-zlib",
        "--with-nghttp2",
        "--with-libpsl",
        "--without-libidn2",
        "--without-brotli",
        "--without-zstd",
        "--without-libssh2",
        "--disable-ldap",
        "--disable-ldaps",
        "--disable-manual",
      ],
    },
    inputs = {
      source = curl_src version source_object_hash,
    },
  }
  in

  {
    include [
      curl,
    ],
  }
