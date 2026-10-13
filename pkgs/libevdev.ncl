fun pkgs =>
  let libevdev_src = {
    version | default = "1.13.4",
    name = "libevdev-src-%{version}",
    tag = "Source",
    object_hash | default = "f00ab8d42ad8b905296fab67e13b871f1a424839331516642100f82ad88127cd",
    origin = {
      tag = "Http",
      url = [
        "https://www.freedesktop.org/software/libevdev/libevdev-%{version}.tar.xz",
        "https://downloads.yoctoproject.org/mirror/sources/libevdev-%{version}.tar.xz",
      ],
    },
  }
  in

  let libevdev = {
    name = "libevdev-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libevdev_src,
    },
  }
  in

  {
    include [
      libevdev_src,
      libevdev,
    ],
  }
