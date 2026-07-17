# pygobject -- Python bindings for GObject-Introspection (the `gi` module). Not
# part of the GNOME session runtime; we build it purely as a build tool, because
# gweather-locations' Locations.bin generator runs `python3` with
# `from gi.repository import GLib`. Meson build against the girepository-2.0 that
# ships inside glib (>= 2.80); the pycairo bindings and tests are off to keep the
# dependency set to python + glib + libffi.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let pygobject_src = fun version =>
    fun hash =>
      {
        name = "pygobject-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/pygobject/3.56/pygobject-%{version}.tar.gz",
        },
      }
  in

  let pygobject = {
    version | default = "3.56.3",
    source_object_hash
      | default
      = "12760e4a0e3d04b6eb95e06f7a27e362c826d567ea613373a92c003b6c70d2d6",
    name = "pygobject-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.python,
        pkgs.glib,
        pkgs.libffi,
        pkgs.gobject_introspection,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.python,
        pkgs.glib,
        pkgs.libffi,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dpycairo=disabled",
        "-Dtests=false",
        "-Dwheel=false",
      ],
    },
    inputs = {
      source = pygobject_src version source_object_hash,
    },
  }
  in

  {
    include [
      pygobject,
    ],
  }
