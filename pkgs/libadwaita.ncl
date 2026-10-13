# libadwaita -- GNOME's GTK4 building blocks (Adwaita widgets). Needed by
# gnome-control-center and gnome-bluetooth, and provides the Adw-1 typelib.
# Meson build against GTK4; fribidi and AppStream (for AdwAboutDialog metainfo)
# are the other real deps. Introspection is on (the typelib); Vala bindings,
# docs, tests and examples are off.
# Configure version and hash through `pkgs.libadwaita_src`.
fun pkgs =>
  let libadwaita_src = {
    version | default = "1.9.2",
    name = "libadwaita-src-%{version}",
    tag = "Source",
    object_hash | default = "6920f813a76c4856591ca56ee842e94efbbe736e8ca2f445c9e9fc3b4e7076f0",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/libadwaita/1.9/libadwaita-%{version}.tar.xz",
    },
  }
  in

  let libadwaita = {
    name = "libadwaita-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
        pkgs.fribidi,
        pkgs.appstream,
        pkgs.sassc,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.fribidi,
        pkgs.appstream,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=enabled",
        "-Dvapi=false",
        "-Ddocumentation=false",
        "-Dtests=false",
        "-Dexamples=false",
      ],
    },
    inputs = {
      source = pkgs.libadwaita_src,
    },
  }
  in

  {
    include [
      libadwaita_src,
      libadwaita,
    ],
  }
