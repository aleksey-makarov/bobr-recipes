let version = "1.24.0" in

fun pkgs =>
  let wayland_src = {
    name = "wayland-src-%{version}",
    tag = "Source",
    object_hash = "f04b6c35fa879bb830ff59146483563c0bc471a3ff53fa8e143f10597d6ff3cb",
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
