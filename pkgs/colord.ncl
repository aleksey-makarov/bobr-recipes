# colord -- color management. mutter links only the client library (libcolord),
# so the daemon is off (-Ddaemon=false), which drops the heavy daemon deps
# (gusb, sqlite, polkit, libgudev). Client lib needs glib + lcms2.
# Configure version and hash through `pkgs.colord_src`.
fun pkgs =>
  let colord_src = {
    version | default = "1.4.8",
    name = "colord-src-%{version}",
    tag = "Source",
    object_hash | default = "21500bd68975312a7f0f3ce6019d9f75f42aacaa75ca7115ec720b5445406896",
    origin = {
      tag = "Http",
      url = [
        "https://www.freedesktop.org/software/colord/releases/colord-%{version}.tar.xz",
        "https://downloads.yoctoproject.org/mirror/sources/colord-%{version}.tar.xz",
      ],
    },
  }
  in

  let colord = {
    name = "colord-%{inputs.source.version}",
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
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.lcms2,
        pkgs.libgusb,
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
      source = pkgs.colord_src,
    },
  }
  in

  {
    include [
      colord_src,
      colord,
    ],
  }
