# geocode-glib -- GObject wrapper around geocoding/reverse-geocoding services.
# Not used directly by gnome-shell, but a hard build dependency of libgweather
# (dependency('geocode-glib-2.0') in its meson.build), which in turn provides the
# GWeather-4.0 typelib gnome-shell imports at startup. Meson build against
# libsoup 3; gtk-doc and installed-tests off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let geocode_glib_src = fun version =>
    fun hash =>
      {
        name = "geocode-glib-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/geocode-glib/3.26/geocode-glib-%{version}.tar.xz",
        },
      }
  in

  let geocode_glib = {
    version | default = "3.26.4",
    source_object_hash
      | default
      = "2d9a6826d158470449a173871221596da0f83ebdcff98b90c7049089056a37aa",
    name = "geocode-glib-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libsoup,
        pkgs.json_glib,
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
        pkgs.json_glib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Denable-introspection=true",
        "-Denable-gtk-doc=false",
        "-Dsoup2=false",
        "-Denable-installed-tests=false",
      ],
    },
    inputs = {
      source = geocode_glib_src version source_object_hash,
    },
  }
  in

  {
    include [
      geocode_glib,
    ],
  }
