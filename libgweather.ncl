# libgweather -- library for weather information and location lookup. gnome-shell
# imports its GWeather-4.0 typelib unconditionally at startup (misc/dependencies.js,
# used by the clock/date menu weather section), so it is a hard dependency of the
# session. Meson build against libsoup 3; introspection on (produces the typelib),
# Vala bindings, gtk-doc and tests off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libgweather_src = fun version =>
    fun hash =>
      {
        name = "libgweather-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libgweather/4.6/libgweather-%{version}.tar.xz",
        },
      }
  in

  let libgweather = {
    version | default = "4.6.0",
    source_object_hash
      | default
      = "7f5d0e8c9685ef2ff46c2f3a57cae48d7bf3540b2d83921f889ef28e6a876788",
    name = "libgweather-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libsoup,
        pkgs.libxml2,
        pkgs.geocode_glib,
        pkgs.json_glib,
        pkgs.gweather_locations,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libsoup,
        pkgs.libxml2,
        pkgs.geocode_glib,
        pkgs.json_glib,
        pkgs.gweather_locations,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=true",
        "-Denable_vala=false",
        "-Dgtk_doc=false",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = libgweather_src version source_object_hash,
    },
  }
  in

  {
    include [
      libgweather,
    ],
  }
