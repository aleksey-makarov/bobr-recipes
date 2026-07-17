# libunistring -- Unicode string library. A dependency of GnuTLS (used as the
# system unistring rather than GnuTLS's bundled copy). Autotools build.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libunistring_src = fun version =>
    fun hash =>
      {
        name = "libunistring-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://ftp.gnu.org/gnu/libunistring/libunistring-%{version}.tar.xz",
        },
      }
  in

  let libunistring = {
    version | default = "1.4.2",
    source_object_hash
      | default
      = "5b46e74377ed7409c5b75e7a96f95377b095623b689d8522620927964a41499c",
    name = "libunistring-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      configure_args = [
        "--libdir=/usr/lib",
        "--disable-static",
      ],
    },
    inputs = {
      source = libunistring_src version source_object_hash,
    },
  }
  in

  { include [ libunistring ] }
