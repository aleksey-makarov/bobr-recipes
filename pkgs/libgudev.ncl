# libgudev -- GObject bindings for libudev (device enumeration), required by
# colord and mutter. Wraps libudev from systemd.
# Configure version and hash through `pkgs.libgudev_src`.
fun pkgs =>
  let libgudev_src = {
    version | default = "238",
    name = "libgudev-src-%{version}",
    tag = "Source",
    object_hash | default = "61266ab1afc9d73dbc60a8b2af73e99d2fdff47d99544d085760e4fa667b5dd1",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/libgudev/%{version}/libgudev-%{version}.tar.xz",
    },
  }
  in

  let libgudev = {
    name = "libgudev-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.systemd_dev,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=enabled",
        "-Dtests=disabled",
        "-Dvapi=disabled",
        "-Dgtk_doc=false",
      ],
    },
    inputs = {
      source = pkgs.libgudev_src,
    },
  }
  in

  {
    include [
      libgudev_src,
      libgudev,
    ],
  }
