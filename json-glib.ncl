let recipe = import "recipe-lib.ncl" in
# json-glib -- JSON parsing/serialization on GObject, used by mutter and other
# GNOME components. `version`/`source_object_hash` are node fields (overridable), as in
# linux.ncl.

let branch = recipe.version_prefix 2 in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "json-glib-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/json-glib/%{branch version}/json-glib-%{version}.tar.xz",
        },
      }
  in

  let json_glib = {
    version | default = "1.10.8",
    source_object_hash | default = "55c5c141a564245b8f8fbe7698663c87a45a7333c2a2c56f06f811ab73b212dd",
    name = "json-glib-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=enabled",
        "-Dgtk_doc=disabled",
        "-Ddocumentation=disabled",
        "-Dman=false",
        "-Dtests=false",
        "-Dconformance=false",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      json_glib,
    ],
  }
