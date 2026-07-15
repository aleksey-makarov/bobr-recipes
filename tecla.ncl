# tecla -- GNOME keyboard layout previewer. gnome-control-center's Keyboard
# panel shells out to the `tecla` application to render a layout preview and
# looks it up via its (data-only) tecla.pc at build time (meson:
# `dependency('tecla', version: '>=47.0')`; otherwise it tries to build tecla as
# a git subproject, which fails offline). GTK4/libadwaita app; needs xkbcommon.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let series = fun v => std.array.at 0 (std.string.split "." v) in

  let tecla_src = fun version =>
    fun hash =>
      {
        name = "tecla-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/tecla/%{series version}/tecla-%{version}.tar.xz",
        },
      }
  in

  let tecla = {
    version | default = "50.0",
    source_object_hash
      | default
      = "2542acb24850082e0ccf6aa17af9651db71d22f0e233fdbf5ed0cffe2e45bc06",
    name = "tecla-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.libxkbcommon,
        pkgs.wayland,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.libxkbcommon,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
      ],
    },
    inputs = {
      source = tecla_src version source_object_hash,
    },
  }
  in

  {
    include [
      tecla,
    ],
  }
