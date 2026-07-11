# at-spi2-core -- accessibility framework. mutter links ATK (`atk`), which this
# package provides along with atspi and the at-spi bus. Introspection is on --
# mutter's GObject introspection pulls in Atk-1.0.gir. X11 support, the GTK2
# adaptor and docs are off; the D-Bus backend is the plain dbus-daemon.
# `version`/`source_object_hash`/`series` are node fields (overridable), as in linux.ncl;
# `series` is the download.gnome.org major.minor directory.

fun pkgs =>
  let mk_src = fun version =>
    fun series =>
      fun hash =>
        {
          name = "at-spi2-core-src-%{version}",
          tag = "Source",
          object_hash = hash,
          origin = {
            tag = "Http",
            url = "https://download.gnome.org/sources/at-spi2-core/%{series}/at-spi2-core-%{version}.tar.xz",
          },
        }
  in

  let at_spi2_core = {
    version | default = "2.58.7",
    source_object_hash | default = "62d2ba47f014e58522e86162eeb57f44b21077112139cfd61ab4c34b027f3f6f",
    series | default = "2.58",
    name = "at-spi2-core-%{version}",
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
        pkgs.glibc_libs,
        pkgs.glib,
        pkgs.dbus,
        pkgs.libxml2,
        pkgs.systemd_libs,
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
      source = mk_src version series source_object_hash,
    },
  }
  in

  {
    include [
      at_spi2_core,
    ],
  }
