# curl -- the libcurl HTTP/transfer library. Pulled in because AppStream links
# libcurl unconditionally (for its metadata pool downloader; unused by our
# consumers, but the library must load). Autotools build against OpenSSL, using
# our existing zlib, nghttp2 (HTTP/2) and libpsl. IDN, brotli, zstd, LDAP, libssh
# and the built-in manual are off to keep the closure down.
# Configure version and hash through `pkgs.curl_src`.
fun pkgs =>
  let curl_src = {
    version | default = "8.16.0",
    name = "curl-src-%{version}",
    tag = "Source",
    object_hash | default = "40c8cddbcb6cc6251c03dea423a472a6cea4037be654ba5cf5dec6eb2d22ff1d",
    origin = {
      tag = "Http",
      url = "https://curl.se/download/curl-%{version}.tar.xz",
    },
  }
  in

  let curl = {
    name = "curl-%{inputs.source.version}",
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
        pkgs.c_runtime,
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
      source = pkgs.curl_src,
    },
  }
  in

  {
    include [
      curl_src,
      curl,
    ],
  }
