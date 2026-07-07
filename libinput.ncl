let version = "1.31.3" in

fun pkgs =>
  let libinput_src = {
    name = "libinput-src-%{version}",
    tag = "Source",
    object_hash = "94dc22de1c2c1b50571be9f9ea39f9707d0a315d291d3fa345b4699fcb82d189",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/libinput/libinput/-/archive/%{version}/libinput-%{version}.tar.gz",
    },
  }
  in

  # Input handling for the compositor. Needs libevdev and libudev (from
  # systemd). libwacom/debug-gui/tests/docs off to keep the dep set minimal.
  let libinput = {
    name = "libinput-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libevdev,
        pkgs.mtdev,
        pkgs.systemd_dev,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.libevdev,
        pkgs.mtdev,
        pkgs.systemd_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dlibwacom=false",
        "-Ddebug-gui=false",
        "-Dtests=false",
        "-Ddocumentation=false",
      ],
    },
    inputs = {
      source = libinput_src,
    },
  }
  in

  {
    include [
      libinput,
    ],
  }
