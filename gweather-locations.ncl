# gweather-locations -- the world locations database for libgweather, split out
# of the main libgweather tarball since 4.6. Provides the compiled Locations.bin
# plus the gweather-locations.pc that libgweather's build looks up for the
# database path, and the data is read at runtime for city/timezone lookups.
# Meson build; the Locations.bin generator runs python3 with PyGObject
# (from gi.repository import GLib), so pygobject and the GLib typelib are build
# tools here. Data only -- no shared libraries.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let gweather_locations_src = fun version =>
    fun hash =>
      {
        name = "gweather-locations-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gweather-locations/2026/gweather-locations-%{version}.tar.xz",
        },
      }
  in

  let gweather_locations = {
    version | default = "2026.2",
    source_object_hash
      | default
      = "e7570a3661e0a752a06387b2032585cf588fc56770b1f9f39f1a55d17b2835fe",
    name = "gweather-locations-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.python,
        pkgs.pygobject,
        pkgs.glib,
        pkgs.gobject_introspection,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
      ],
    },
    inputs = {
      source = gweather_locations_src version source_object_hash,
    },
  }
  in

  {
    include [
      gweather_locations,
    ],
  }
