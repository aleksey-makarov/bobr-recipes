# libgweather -- library for weather information and location lookup. gnome-shell
# imports its GWeather-4.0 typelib unconditionally at startup (misc/dependencies.js,
# used by the clock/date menu weather section), so it is a hard dependency of the
# session. Meson build against libsoup 3; introspection on (produces the typelib),
# Vala bindings, gtk-doc and tests off.
# Configure version and hash through `pkgs.libgweather_src`.
fun pkgs =>
  let libgweather_src = {
    version | default = "4.6.0",
    name = "libgweather-src-%{version}",
    tag = "Source",
    object_hash | default = "7f5d0e8c9685ef2ff46c2f3a57cae48d7bf3540b2d83921f889ef28e6a876788",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/libgweather/4.6/libgweather-%{version}.tar.xz",
    },
  }
  in

  let libgweather = {
    name = "libgweather-%{inputs.source.version}",
    tag = "Meson",
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
        pkgs.c_runtime,
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
      source = pkgs.libgweather_src,
    },
  }
  in

  {
    include [
      libgweather_src,
      libgweather,
    ],
  }
