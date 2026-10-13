# vala -- the Vala programming language compiler (valac). A build tool only:
# gsound (and other GNOME libraries) are written in Vala and need valac to
# generate their C. The release tarball ships the compiler's pre-generated C, so
# it bootstraps without an existing valac; flex and bison regenerate the scanner
# and parser. valadoc is disabled to avoid the graphviz (libgvc) dependency.
# Configure version and hash through `pkgs.vala_src`.
fun pkgs =>
  let vala_src = {
    version | default = "0.56.19",
    name = "vala-src-%{version}",
    tag = "Source",
    object_hash | default = "5ad7cbbfcc0de61b403d6797c9ef60455bfbebd8e162aec33b5b0b097adfb9d5",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/vala/0.56/vala-%{version}.tar.xz",
    },
  }
  in

  let vala = {
    name = "vala-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.glib,
        pkgs.flex,
        pkgs.bison,
        pkgs.gobject_introspection,
        # g-ir-scanner imports distutils (gone in 3.13); setuptools provides it.
        pkgs.python_setuptools,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
      ],
    },
    config = {
      configure_args = [
        "--disable-valadoc",
      ],
    },
    inputs = {
      source = pkgs.vala_src,
    },
  }
  in

  {
    include [
      vala_src,
      vala,
    ],
  }
