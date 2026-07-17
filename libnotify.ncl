# libnotify -- desktop notification library (org.freedesktop.Notifications
# client). A hard dependency of gnome-settings-daemon (media-keys, power, etc.).
# Meson build; the library itself needs only glib + gdk-pixbuf. The gtk+-3.0
# dependency is pulled in only by the test programs, so tests are off; docs and
# man pages off too. Introspection stays on in case a consumer wants the typelib.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libnotify_src = fun version =>
    fun hash =>
      {
        name = "libnotify-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libnotify/0.8/libnotify-%{version}.tar.xz",
        },
      }
  in

  let libnotify = {
    version | default = "0.8.8",
    source_object_hash
      | default
      = "23420ef619dc2cb5aebad613f4823a2fa41c07e5a1d05628d40f6ec4b35bfddd",
    name = "libnotify-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gdk_pixbuf,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gdk_pixbuf,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dtests=false",
        "-Dman=false",
        "-Dgtk_doc=false",
        "-Ddocbook_docs=disabled",
      ],
    },
    inputs = {
      source = libnotify_src version source_object_hash,
    },
  }
  in

  {
    include [
      libnotify,
    ],
  }
