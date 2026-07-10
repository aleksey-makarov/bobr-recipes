let version = "1.24.0" in

fun pkgs =>
  let wayland_src = {
    name = "wayland-src-%{version}",
    tag = "Source",
    object_hash = "82892487a01ad67b334eca83b54317a7c86a03a89cfadacfef5211f11a5d0536",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/wayland/wayland/-/releases/%{version}/downloads/wayland-%{version}.tar.xz",
    },
  }
  in

  # Core Wayland: libwayland-{client,server,cursor,egl} + the wayland-scanner
  # build tool. dtd_validation off avoids a libxml2 build dependency.
  let wayland = {
    name = "wayland-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libffi,
        pkgs.expat,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.libffi,
        pkgs.expat,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddocumentation=false",
        "-Dtests=false",
        "-Ddtd_validation=false",
      ],
    },
    inputs = {
      source = wayland_src,
    },
  }
  in

  {
    include [
      wayland,
    ],
  }
