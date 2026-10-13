# nghttp2 -- HTTP/2 C library (libnghttp2). libsoup 3 links it for HTTP/2
# support. Built library-only (--enable-lib-only), so the applications and their
# deps (libev, openssl, c-ares, jansson, ...) are skipped. Plain Autotools.
# Configure version and hash through `pkgs.nghttp2_src`.
fun pkgs =>
  let nghttp2_src = {
    version | default = "1.69.0",
    name = "nghttp2-src-%{version}",
    tag = "Source",
    object_hash | default = "1fb324b6ec2c56f6bde0658f4139ffd8209fa9e77ce98fd7a5f63af8d0e508ad",
    origin = {
      tag = "Http",
      url = "https://github.com/nghttp2/nghttp2/releases/download/v%{version}/nghttp2-%{version}.tar.xz",
    },
  }
  in

  let nghttp2 = {
    name = "nghttp2-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--enable-lib-only",
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.nghttp2_src,
    },
  }
  in

  {
    include [
      nghttp2_src,
      nghttp2,
    ],
  }
