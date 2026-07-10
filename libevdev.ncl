let version = "1.13.4" in

fun pkgs =>
  let libevdev_src = {
    name = "libevdev-src-%{version}",
    tag = "Source",
    object_hash = "f00ab8d42ad8b905296fab67e13b871f1a424839331516642100f82ad88127cd",
    origin = {
      tag = "Http",
      url = "https://www.freedesktop.org/software/libevdev/libevdev-%{version}.tar.xz",
    },
  }
  in

  let libevdev = {
    name = "libevdev-%{version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dtests=disabled",
        "-Ddocumentation=disabled",
      ],
    },
    inputs = {
      source = libevdev_src,
    },
  }
  in

  {
    include [
      libevdev,
    ],
  }
