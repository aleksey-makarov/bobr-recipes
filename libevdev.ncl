
fun pkgs =>
  let libevdev_src = fun version => fun hash => {
    name = "libevdev-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.freedesktop.org/software/libevdev/libevdev-%{version}.tar.xz",
    },
  }
  in

  let libevdev = {
    version | default = "1.13.4",
    source_object_hash | default = "f00ab8d42ad8b905296fab67e13b871f1a424839331516642100f82ad88127cd",
    name = "libevdev-%{version}",
    tag = "MesonInstall",
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
      source = libevdev_src version source_object_hash,
    },
  }
  in

  {
    include [
      libevdev,
    ],
  }
