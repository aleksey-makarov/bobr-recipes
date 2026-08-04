# libxslt -- XSLT engine and the xsltproc tool, built on libxml2. Provided as a
# build tool: many GNOME packages render their man pages from DocBook XML with
# xsltproc (AppStream, gdm, ...). Autotools build; the Python bindings, the
# libgcrypt crypto extensions and the debugger are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libxslt_src = fun version =>
    fun hash =>
      {
        name = "libxslt-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libxslt/1.1/libxslt-%{version}.tar.xz",
        },
      }
  in

  let libxslt = {
    version | default = "1.1.45",
    source_object_hash
      | default
      = "9acfe68419c4d06a45c550321b3212762d92f41465062ca4ea19e632ee5d216e",
    name = "libxslt-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libxml2,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libxml2,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--without-python",
        "--without-crypto",
        "--without-debugger",
      ],
    },
    inputs = {
      source = libxslt_src version source_object_hash,
    },
  }
  in

  {
    include [
      libxslt,
    ],
  }
