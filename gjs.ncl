let recipe = import "recipe-lib.ncl" in
# gjs -- GNOME JavaScript bindings: the JS runtime gnome-shell (and GNOME JS
# apps) run on. A C/C++ library embedding SpiderMonkey (mozjs-140) and exposing
# GObject-Introspection to JS. Plain Meson, so the `Meson` synthetic builder
# handles it. Links libmozjs-140 (C++), glib/gio/girepository (from glib), and
# cairo/cairo-gobject.
#
# Optional bits are off: readline (console line-editing), the sysprof profiler,
# installed tests, and the gtk/dbus test suites -- gnome-shell needs libgjs, not
# those. `version`/`source_object_hash` are node fields (overridable).
let series = recipe.version_prefix 2 in

fun pkgs =>
  let gjs_src = fun version =>
    fun hash =>
      {
        name = "gjs-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gjs/%{series version}/gjs-%{version}.tar.xz",
        },
      }
  in

  let gjs = {
    version | default = "1.88.1",
    source_object_hash
      | default
      = "767bab80e665d672cb00563c25f0b392a9ec8c2996ed1d4454c698b4c2f0a3d9",
    name = "gjs-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.cairo,
        pkgs.mozjs,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.cairo,
        pkgs.mozjs,
        # gjs links libgirepository and loads typelibs at runtime; ldd sees the
        # lib but not the gobject-introspection package that ships it + the base
        # GIRepository typelib.
        pkgs.gobject_introspection,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dreadline=disabled",
        "-Dprofiler=disabled",
        "-Dinstalled_tests=false",
        "-Dskip_gtk_tests=true",
        "-Dskip_dbus_tests=true",
      ],
    },
    inputs = {
      source = gjs_src version source_object_hash,
    },
  }
  in

  {
    include [
      gjs,
    ],
  }
