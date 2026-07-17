# colord -- color management. mutter links only the client library (libcolord),
# so the daemon is off (-Ddaemon=false), which drops the heavy daemon deps
# (gusb, sqlite, polkit, libgudev). Client lib needs glib + lcms2.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

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
    version | default = "1.4.8",
    source_object_hash | default = "21500bd68975312a7f0f3ce6019d9f75f42aacaa75ca7115ec720b5445406896",
    name = "colord-%{version}",
    tag = "MesonInstall",
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      colord,
    ],
  }
