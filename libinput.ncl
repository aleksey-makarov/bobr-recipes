
fun pkgs =>
  let libinput_src = fun version => fun hash => {
    name = "libinput-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/libinput/libinput/-/archive/%{version}/libinput-%{version}.tar.gz",
    },
  }
  in

  # Input handling for the compositor. Needs libevdev and libudev (from
  # systemd). libwacom/debug-gui/tests/docs off to keep the dep set minimal.
  let libinput = {
    version | default = "1.31.3",
    source_object_hash | default = "b6749bf6f1890f6631c0a70a027c35fec9d2e096a39f720548896e41474a9854",
    name = "libinput-%{version}",
    tag = "MesonInstall",
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
      source = libinput_src version source_object_hash,
    },
  }
  in

  {
    include [
      libinput,
    ],
  }
