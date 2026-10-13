# libwacom -- library describing graphics tablets. A hard dependency of
# gnome-control-center (the Wacom panel; the dep is not optional there). Meson
# build against glib, libgudev and libevdev. Documentation and tests are off.
# Configure version and hash through `pkgs.libwacom_src`.
fun pkgs =>
  let libwacom_src = {
    version | default = "2.19.0",
    name = "libwacom-src-%{version}",
    tag = "Source",
    object_hash | default = "8dd84e75d322aa5f33b2fe781cb67efa5706fedcf483737b4657557f33055a93",
    origin = {
      tag = "Http",
      url = "https://github.com/linuxwacom/libwacom/releases/download/libwacom-%{version}/libwacom-%{version}.tar.xz",
    },
  }
  in

  let libwacom = {
    name = "libwacom-%{inputs.source.version}",
    tag = "Meson",
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
        pkgs.c_runtime,
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
      source = pkgs.libwacom_src,
    },
  }
  in

  {
    include [
      libwacom_src,
      libwacom,
    ],
  }
