# libgusb -- GObject wrapper around libusb, required by colord. Uses gio,
# libusb, json-glib; embeds vendor/product names from hwdata's usb.ids (the
# default usb_ids path /usr/share/hwdata/usb.ids). `version`/`source_object_hash` are node
# fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libgusb-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/hughsie/libgusb/releases/download/%{version}/libgusb-%{version}.tar.xz",
        },
      }
  in

  let libgusb = {
    version | default = "0.4.9",
    source_object_hash | default = "9df5ef301d6a4b361002aa52cce1165a87a89744055879bdbab31e7e86f1e846",
    name = "libgusb-%{version}",
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
        pkgs.glibc_libs,
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libgusb,
    ],
  }
