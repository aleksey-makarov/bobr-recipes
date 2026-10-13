# libgusb -- GObject wrapper around libusb, required by colord. Uses gio,
# libusb, json-glib; embeds vendor/product names from hwdata's usb.ids (the
# default usb_ids path /usr/share/hwdata/usb.ids).
# Configure version and hash through `pkgs.libgusb_src`.
fun pkgs =>
  let libgusb_src = {
    version | default = "0.4.9",
    name = "libgusb-src-%{version}",
    tag = "Source",
    object_hash | default = "9df5ef301d6a4b361002aa52cce1165a87a89744055879bdbab31e7e86f1e846",
    origin = {
      tag = "Http",
      url = "https://github.com/hughsie/libgusb/releases/download/%{version}/libgusb-%{version}.tar.xz",
    },
  }
  in

  let libgusb = {
    name = "libgusb-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libusb,
        pkgs.json_glib,
        pkgs.hwdata,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.libusb,
        pkgs.json_glib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dtests=false",
        "-Dvapi=false",
        "-Ddocs=false",
        "-Dintrospection=true",
        "-Dumockdev=disabled",
      ],
    },
    inputs = {
      source = pkgs.libgusb_src,
    },
  }
  in

  {
    include [
      libgusb_src,
      libgusb,
    ],
  }
