# libgusb -- GObject wrapper around libusb, required by colord. Uses gio,
# libusb, json-glib; embeds vendor/product names from hwdata's usb.ids (the
# default usb_ids path /usr/share/hwdata/usb.ids). `version`/`hashes` are node
# fields (overridable), as in linux.ncl.
let default_version = "0.4.9" in
let default_hashes = {
  "0.4.9" = "da582569c4dded90fb970b3e65eb5873b54a377bca2e5c2ffe9fd5d49aabdd53",
}
in

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
    version | default = default_version,
    hashes | default = default_hashes,
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      libgusb,
    ],
  }
