# geoclue -- geolocation service. gnome-shell imports its Geoclue-2.0 typelib
# unconditionally at startup (misc/dependencies.js), so libgeoclue + that typelib
# are a hard dependency of the session even though we ship no location provider.
# We build only the convenience client library (libgeoclue) with introspection;
# the daemon/backend and all network location sources are off, which keeps the
# dependency set down to glib. Location will simply be unavailable at runtime,
# which gnome-shell handles gracefully -- only the typelib import must succeed.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let geoclue_src = fun version =>
    fun hash =>
      {
        name = "geoclue-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gitlab.freedesktop.org/geoclue/geoclue/-/archive/%{version}/geoclue-%{version}.tar.gz",
        },
      }
  in

  let geoclue = {
    version | default = "2.8.2",
    source_object_hash
      | default
      = "5435f7d48105fe89a4259f807658281e854881267254bcd4eeac6e26c222055b",
    name = "geoclue-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.dbus,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dlibgeoclue=true",
        "-Dintrospection=true",
        "-Dvapi=false",
        "-Denable-backend=false",
        "-Ddemo-agent=false",
        "-Dgtk-doc=false",
      ],
    },
    inputs = {
      source = geoclue_src version source_object_hash,
    },
  }
  in

  {
    include [
      geoclue,
    ],
  }
