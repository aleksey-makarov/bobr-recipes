# nghttp2 -- HTTP/2 C library (libnghttp2). libsoup 3 links it for HTTP/2
# support. Built library-only (--enable-lib-only), so the applications and their
# deps (libev, openssl, c-ares, jansson, ...) are skipped. Plain Autotools.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let nghttp2_src = fun version =>
    fun hash =>
      {
        name = "nghttp2-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/nghttp2/nghttp2/releases/download/v%{version}/nghttp2-%{version}.tar.xz",
        },
      }
  in

  let nghttp2 = {
    version | default = "1.69.0",
    source_object_hash
      | default
      = "1fb324b6ec2c56f6bde0658f4139ffd8209fa9e77ce98fd7a5f63af8d0e508ad",
    name = "nghttp2-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--enable-lib-only",
        "--disable-static",
      ],
    },
    inputs = {
      source = nghttp2_src version source_object_hash,
    },
  }
  in

  {
    include [
      nghttp2,
    ],
  }
