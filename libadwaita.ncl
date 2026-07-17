# libadwaita -- GNOME's GTK4 building blocks (Adwaita widgets). Needed by
# gnome-control-center and gnome-bluetooth, and provides the Adw-1 typelib.
# Meson build against GTK4; fribidi and AppStream (for AdwAboutDialog metainfo)
# are the other real deps. Introspection is on (the typelib); Vala bindings,
# docs, tests and examples are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libadwaita_src = fun version =>
    fun hash =>
      {
        name = "libadwaita-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libadwaita/1.9/libadwaita-%{version}.tar.xz",
        },
      }
  in

  let libadwaita = {
    version | default = "1.9.2",
    source_object_hash
      | default
      = "6920f813a76c4856591ca56ee842e94efbbe736e8ca2f445c9e9fc3b4e7076f0",
    name = "libadwaita-%{version}",
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
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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
      source = libadwaita_src version source_object_hash,
    },
  }
  in

  {
    include [
      libadwaita,
    ],
  }
