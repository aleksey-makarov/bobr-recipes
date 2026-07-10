# colord -- color management. mutter links only the client library (libcolord),
# so the daemon is off (-Ddaemon=false), which drops the heavy daemon deps
# (gusb, sqlite, polkit, libgudev). Client lib needs glib + lcms2.
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "1.4.8" in
let default_hashes = {
  "1.4.8" = "1baf98245a9e296e8a46cc34d06647cd23dca2bf23b7ec1f986643fe30bbbd1a",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "colord-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://www.freedesktop.org/software/colord/releases/colord-%{version}.tar.xz",
        },
      }
  in

  let colord = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "colord-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.lcms2,
        pkgs.sqlite,
        pkgs.libgusb,
        pkgs.libgudev,
        pkgs.systemd_dev,
        pkgs.gettext,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib,
        pkgs.lcms2,
        pkgs.sqlite,
        pkgs.libgusb,
        pkgs.libgudev,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddaemon=false",
        "-Dsystemd=false",
        "-Dargyllcms_sensor=false",
        "-Dudev_rules=false",
        "-Dbash_completion=false",
        "-Dprint_profiles=false",
        "-Dvapi=false",
        "-Dman=false",
        "-Ddocs=false",
        "-Dtests=false",
        "-Dintrospection=true",
      ],
    },
    inputs = {
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      colord,
    ],
  }
