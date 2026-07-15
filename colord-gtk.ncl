# colord-gtk -- GTK bindings for colord, providing colord-gtk4 (used by
# gnome-control-center's Color panel: `dependency('colord-gtk4')`). Meson build
# against colord, GTK4 and lcms2. Only the GTK4 binding is built (no GTK2/GTK3);
# docs, tests, man pages and the Vala binding are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let colord_gtk_src = fun version =>
    fun hash =>
      {
        name = "colord-gtk-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.freedesktop.org/software/colord/releases/colord-gtk-%{version}.tar.xz",
        },
      }
  in

  let colord_gtk = {
    version | default = "0.3.1",
    source_object_hash
      | default
      = "c176b889b75630a17f4e3d7ef24c09a3e12368e633496087459c8b53ac3a122d",
    name = "colord-gtk-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.colord,
        pkgs.gtk4,
        pkgs.lcms2,
        pkgs.gobject_introspection,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.colord,
        pkgs.gtk4,
        pkgs.lcms2,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dgtk4=true",
        "-Dgtk2=false",
        "-Dgtk3=false",
        "-Dvapi=false",
        "-Ddocs=false",
        "-Dtests=false",
        "-Dman=false",
      ],
    },
    inputs = {
      source = colord_gtk_src version source_object_hash,
    },
  }
  in

  {
    include [
      colord_gtk,
    ],
  }
