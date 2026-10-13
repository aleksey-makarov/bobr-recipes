# at-spi2-core -- accessibility framework. mutter links ATK (`atk`), which this
# package provides along with atspi and the at-spi bus. Introspection is on --
# mutter's GObject introspection pulls in Atk-1.0.gir. X11 support, the GTK2
# adaptor and docs are off; the D-Bus backend is the plain dbus-daemon.
let recipe = import "../recipe-lib.ncl" in
let series = recipe.version_prefix 2 in

fun pkgs =>
  let at_spi2_core_src = {
    version | default = "2.58.7",
    name = "at-spi2-core-src-%{version}",
    tag = "Source",
    object_hash | default = "62d2ba47f014e58522e86162eeb57f44b21077112139cfd61ab4c34b027f3f6f",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/at-spi2-core/%{series version}/at-spi2-core-%{version}.tar.xz",
    },
  }
  in

  let at_spi2_core = {
    name = "at-spi2-core-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.dbus,
        pkgs.libxml2,
        pkgs.systemd_dev,
        pkgs.gettext,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.dbus,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dx11=disabled",
        # Introspection on: mutter's GObject introspection needs Atk-1.0.gir.
        "-Dintrospection=enabled",
        "-Ddocs=false",
        "-Dgtk2_atk_adaptor=false",
        "-Ddefault_bus=dbus-daemon",
      ],
    },
    inputs = {
      source = pkgs.at_spi2_core_src,
    },
  }
  in

  {
    include [
      at_spi2_core_src,
      at_spi2_core,
    ],
  }
