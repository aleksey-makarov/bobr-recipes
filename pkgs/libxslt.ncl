# libxslt -- XSLT engine and the xsltproc tool, built on libxml2. Provided as a
# build tool: many GNOME packages render their man pages from DocBook XML with
# xsltproc (AppStream, gdm, ...). Autotools build; the Python bindings, the
# libgcrypt crypto extensions and the debugger are off.
# Configure version and hash through `pkgs.libxslt_src`.
fun pkgs =>
  let libxslt_src = {
    version | default = "1.1.45",
    name = "libxslt-src-%{version}",
    tag = "Source",
    object_hash | default = "9acfe68419c4d06a45c550321b3212762d92f41465062ca4ea19e632ee5d216e",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/libxslt/1.1/libxslt-%{version}.tar.xz",
    },
  }
  in

  let libxslt = {
    name = "libxslt-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.libxml2,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libxslt_src,
    },
  }
  in

  {
    include [
      libxslt_src,
      libxslt,
    ],
  }
