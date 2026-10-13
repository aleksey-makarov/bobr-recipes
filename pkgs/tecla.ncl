let recipe = import "../recipe-lib.ncl" in
# tecla -- GNOME keyboard layout previewer. gnome-control-center's Keyboard
# panel shells out to the `tecla` application to render a layout preview and
# looks it up via its (data-only) tecla.pc at build time (meson:
# `dependency('tecla', version: '>=47.0')`; otherwise it tries to build tecla as
# a git subproject, which fails offline). GTK4/libadwaita app; needs xkbcommon.
# Configure version and hash through `pkgs.tecla_src`.
fun pkgs =>
  let series = recipe.version_prefix 1 in

  let tecla_src = {
    version | default = "50.0",
    name = "tecla-src-%{version}",
    tag = "Source",
    object_hash | default = "2542acb24850082e0ccf6aa17af9651db71d22f0e233fdbf5ed0cffe2e45bc06",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/tecla/%{series version}/tecla-%{version}.tar.xz",
    },
  }
  in

  let tecla = {
    name = "tecla-%{inputs.source.version}",
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
        pkgs.c_runtime,
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
      source = pkgs.tecla_src,
    },
  }
  in

  {
    include [
      tecla_src,
      tecla,
    ],
  }
