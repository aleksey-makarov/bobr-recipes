let version = "1.13.4" in

fun pkgs =>
  let libevdev_src = {
    name = "libevdev-src-%{version}",
    tag = "Source",
    object_hash = "b61a9d680e084eb1e92714ca252c6c18175ba1fe6260f3eaac982b46089e7b7a",
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
