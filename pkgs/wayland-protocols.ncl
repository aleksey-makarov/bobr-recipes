fun pkgs =>
  let wayland_protocols_src = {
    version | default = "1.48",
    name = "wayland-protocols-src-%{version}",
    tag = "Source",
    object_hash | default = "398036ac0eb6484982ddbde7ff86848d753231f9cdeeae983f06b52946625aa1",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/%{version}/downloads/wayland-protocols-%{version}.tar.xz",
    },
  }
  in

  # Protocol XML + pkg-config data only (no libraries). Needs wayland-scanner
  # from wayland at build time.
  let wayland_protocols = {
    name = "wayland-protocols-%{inputs.source.version}",
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
      source = pkgs.wayland_protocols_src,
    },
  }
  in

  {
    include [
      wayland_protocols_src,
      wayland_protocols,
    ],
  }
