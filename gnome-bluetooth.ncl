# gnome-bluetooth -- Bluetooth device management library and panel. gnome-shell,
# when built with bluetooth support, imports its GnomeBluetooth-3.0 typelib for
# the Bluetooth quick-settings toggle. GTK4-based (no GTK3), so it fits our stack.
# Meson build; introspection on (produces the typelib), the bluetooth-sendto tool
# and docs off. There is no Bluetooth hardware in the QEMU guest, so the indicator
# stays idle -- but building it with -Dbluetooth=true also gives gnome-shell an
# early async import in _setupIndicators, which its startup ordering relies on.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let gnome_bluetooth_src = fun version =>
    fun hash =>
      {
        name = "gnome-bluetooth-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gnome-bluetooth/47/gnome-bluetooth-%{version}.tar.xz",
        },
      }
  in

  let gnome_bluetooth = {
    version | default = "47.2",
    source_object_hash
      | default
      = "41f20e6d6176b72590af63552b232d83f2fffdd77ecfaa5eaf32c5a4a86fad64",
    name = "gnome-bluetooth-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.gtk4,
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
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.gtk4,
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
      source = gnome_bluetooth_src version source_object_hash,
    },
  }
  in

  {
    include [
      gnome_bluetooth,
    ],
  }
