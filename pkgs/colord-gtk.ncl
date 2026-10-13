# colord-gtk -- GTK bindings for colord, providing colord-gtk4 (used by
# gnome-control-center's Color panel: `dependency('colord-gtk4')`). Meson build
# against colord, GTK4 and lcms2. Only the GTK4 binding is built (no GTK2/GTK3);
# docs, tests, man pages and the Vala binding are off.
# Configure version and hash through `pkgs.colord_gtk_src`.
fun pkgs =>
  let colord_gtk_src = {
    version | default = "0.3.1",
    name = "colord-gtk-src-%{version}",
    tag = "Source",
    object_hash | default = "c176b889b75630a17f4e3d7ef24c09a3e12368e633496087459c8b53ac3a122d",
    origin = {
      tag = "Http",
      url = [
        "https://www.freedesktop.org/software/colord/releases/colord-gtk-%{version}.tar.xz",
        "https://deb.debian.org/debian/pool/main/c/colord-gtk/colord-gtk_%{version}.orig.tar.xz",
      ],
    },
  }
  in

  let colord_gtk = {
    name = "colord-gtk-%{inputs.source.version}",
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
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.colord,
        pkgs.gtk4,
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
      source = pkgs.colord_gtk_src,
    },
  }
  in

  {
    include [
      colord_gtk_src,
      colord_gtk,
    ],
  }
