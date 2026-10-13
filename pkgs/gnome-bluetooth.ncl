# gnome-bluetooth -- Bluetooth device management library and panel. gnome-shell,
# when built with bluetooth support, imports its GnomeBluetooth-3.0 typelib for
# the Bluetooth quick-settings toggle. GTK4-based (no GTK3), so it fits our stack.
# Meson build; introspection on (produces the typelib), the bluetooth-sendto tool
# and docs off. There is no Bluetooth hardware in the QEMU guest, so the indicator
# stays idle -- but building it with -Dbluetooth=true also gives gnome-shell an
# early async import in _setupIndicators, which its startup ordering relies on.
# Configure version and hash through `pkgs.gnome_bluetooth_src`.
fun pkgs =>
  let gnome_bluetooth_src = {
    version | default = "47.2",
    name = "gnome-bluetooth-src-%{version}",
    tag = "Source",
    object_hash | default = "41f20e6d6176b72590af63552b232d83f2fffdd77ecfaa5eaf32c5a4a86fad64",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/gnome-bluetooth/47/gnome-bluetooth-%{version}.tar.xz",
    },
  }
  in

  let gnome_bluetooth = {
    name = "gnome-bluetooth-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.gsound,
        pkgs.libnotify,
        pkgs.systemd_dev,
        pkgs.upower,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.gtk4,
        pkgs.libadwaita,
        pkgs.gsound,
        pkgs.libnotify,
        pkgs.systemd_libs,
        pkgs.upower,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dsendto=false",
        "-Dgtk_doc=false",
        "-Dintrospection=true",
      ],
    },
    inputs = {
      source = pkgs.gnome_bluetooth_src,
    },
  }
  in

  {
    include [
      gnome_bluetooth_src,
      gnome_bluetooth,
    ],
  }
