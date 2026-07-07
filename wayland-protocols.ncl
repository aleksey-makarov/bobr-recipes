let version = "1.48" in

fun pkgs =>
  let wayland_protocols_src = {
    name = "wayland-protocols-src-%{version}",
    tag = "Source",
    object_hash = "f02b5debe1cbea33b33e10a5e1e9b17f965bf029f74ad90e3dd20aa5f9ec1d0c",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/%{version}/downloads/wayland-protocols-%{version}.tar.xz",
    },
  }
  in

  # Protocol XML + pkg-config data only (no libraries). Needs wayland-scanner
  # from wayland at build time.
  let wayland_protocols = {
    name = "wayland-protocols-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.wayland,
      ],
      runtime = [],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = wayland_protocols_src,
    },
  }
  in

  {
    include [
      wayland_protocols,
    ],
  }
