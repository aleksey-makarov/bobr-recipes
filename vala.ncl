# vala -- the Vala programming language compiler (valac). A build tool only:
# gsound (and other GNOME libraries) are written in Vala and need valac to
# generate their C. The release tarball ships the compiler's pre-generated C, so
# it bootstraps without an existing valac; flex and bison regenerate the scanner
# and parser. valadoc is disabled to avoid the graphviz (libgvc) dependency.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let vala_src = fun version =>
    fun hash =>
      {
        name = "vala-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/vala/0.56/vala-%{version}.tar.xz",
        },
      }
  in

  let vala = {
    version | default = "0.56.19",
    source_object_hash
      | default
      = "5ad7cbbfcc0de61b403d6797c9ef60455bfbebd8e162aec33b5b0b097adfb9d5",
    name = "vala-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.flex,
        pkgs.bison,
        pkgs.gobject_introspection,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
      ],
    },
    config = {
      configure_args = [
        "--disable-valadoc",
      ],
    },
    inputs = {
      source = vala_src version source_object_hash,
    },
  }
  in

  {
    include [
      vala,
    ],
  }
