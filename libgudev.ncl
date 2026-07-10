# libgudev -- GObject bindings for libudev (device enumeration), required by
# colord and mutter. Wraps libudev from systemd. `version`/`hashes` are node
# fields (overridable), as in linux.ncl.
let default_version = "238" in
let default_hashes = {
  "238" = "61266ab1afc9d73dbc60a8b2af73e99d2fdff47d99544d085760e4fa667b5dd1",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libgudev-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/libgudev/%{version}/libgudev-%{version}.tar.xz",
        },
      }
  in

  let libgudev = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "libgudev-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.systemd_dev,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      libgudev,
    ],
  }
