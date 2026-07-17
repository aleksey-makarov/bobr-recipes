# blueprint-compiler -- compiles Blueprint (.blp) UI descriptions to GtkBuilder
# XML at build time. A build-only tool required by gnome-control-center 50
# (meson: `find_program('blueprint-compiler', version: '>= 0.19')`). Pure Python;
# it is installed to /usr and invoked via python3 inside the build sandbox.
# Upstream has no release tarballs on download.gnome.org, so the source is the
# GitLab tag archive.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let bp_src = fun version =>
    fun hash =>
      {
        name = "blueprint-compiler-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gitlab.gnome.org/GNOME/blueprint-compiler/-/archive/v%{version}/blueprint-compiler-v%{version}.tar.gz",
        },
      }
  in

  let blueprint_compiler = {
    version | default = "0.22.2",
    source_object_hash
      | default
      = "ba4dddeb22a1929ed5987e74cb69c592e22bc74f0c04cfdb9028b907cf688af6",
    name = "blueprint-compiler-v%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.python,
        pkgs.pkgconf,
      ],
      # blueprintcompiler.gir imports `gi` (PyGObject) and requires the
      # GIRepository-3.0 typelib (gobject-introspection), plus the GLib/GObject
      # typelibs, to read the GTK typelibs while compiling .blp files. So the
      # tool's runtime closure -- which is merged into every consumer's build
      # sandbox -- must carry PyGObject and gobject-introspection.
      runtime = [
        pkgs.python,
        pkgs.pygobject,
        pkgs.gobject_introspection,
        pkgs.glib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddocs=false",
      ],
    },
    inputs = {
      source = bp_src version source_object_hash,
    },
  }
  in

  {
    include [
      blueprint_compiler,
    ],
  }
