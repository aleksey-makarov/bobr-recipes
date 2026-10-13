let recipe = import "../recipe-lib.ncl" in
# json-glib -- JSON parsing/serialization on GObject, used by mutter and other
# GNOME components.
# Configure version and hash through `pkgs.json_glib_src`.
let branch = recipe.version_prefix 2 in

fun pkgs =>
  let json_glib_src = {
    version | default = "1.10.8",
    name = "json-glib-src-%{version}",
    tag = "Source",
    object_hash | default = "55c5c141a564245b8f8fbe7698663c87a45a7333c2a2c56f06f811ab73b212dd",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/json-glib/%{branch version}/json-glib-%{version}.tar.xz",
    },
  }
  in

  let json_glib = {
    name = "json-glib-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.json_glib_src,
    },
  }
  in

  {
    include [
      json_glib_src,
      json_glib,
    ],
  }
