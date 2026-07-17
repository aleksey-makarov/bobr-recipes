
fun pkgs =>
  let wayland_src = fun version => fun hash => {
    name = "wayland-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/wayland/wayland/-/releases/%{version}/downloads/wayland-%{version}.tar.xz",
    },
  }
  in

  # Core Wayland: libwayland-{client,server,cursor,egl} + the wayland-scanner
  # build tool. dtd_validation off avoids a libxml2 build dependency.
  let wayland = {
    version | default = "1.24.0",
    source_object_hash | default = "82892487a01ad67b334eca83b54317a7c86a03a89cfadacfef5211f11a5d0536",
    name = "wayland-%{version}",
    tag = "MesonInstall",
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
      source = wayland_src version source_object_hash,
    },
  }
  in

  {
    include [
      wayland,
    ],
  }
