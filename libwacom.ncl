# libwacom -- library describing graphics tablets. A hard dependency of
# gnome-control-center (the Wacom panel; the dep is not optional there). Meson
# build against glib, libgudev and libevdev. Documentation and tests are off.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let libwacom_src = fun version =>
    fun hash =>
      {
        name = "libwacom-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/linuxwacom/libwacom/releases/download/libwacom-%{version}/libwacom-%{version}.tar.xz",
        },
      }
  in

  let libwacom = {
    version | default = "2.19.0",
    source_object_hash
      | default
      = "8dd84e75d322aa5f33b2fe781cb67efa5706fedcf483737b4657557f33055a93",
    name = "libwacom-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib,
        pkgs.libgudev,
        pkgs.systemd_dev,
        pkgs.libevdev,
        pkgs.gobject_introspection,
        pkgs.python,
        pkgs.gettext,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.glib,
        pkgs.libgudev,
        pkgs.libevdev,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddocumentation=disabled",
        "-Dtests=disabled",
      ],
    },
    inputs = {
      source = libwacom_src version source_object_hash,
    },
  }
  in

  {
    include [
      libwacom,
    ],
  }
