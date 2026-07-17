
fun pkgs =>
  let wayland_protocols_src = fun version => fun hash => {
    name = "wayland-protocols-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/wayland/wayland-protocols/-/releases/%{version}/downloads/wayland-protocols-%{version}.tar.xz",
    },
  }
  in

  # Protocol XML + pkg-config data only (no libraries). Needs wayland-scanner
  # from wayland at build time.
  let wayland_protocols = {
    version | default = "1.48",
    source_object_hash | default = "398036ac0eb6484982ddbde7ff86848d753231f9cdeeae983f06b52946625aa1",
    name = "wayland-protocols-%{version}",
    tag = "MesonInstall",
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
      source = wayland_protocols_src version source_object_hash,
    },
  }
  in

  {
    include [
      wayland_protocols,
    ],
  }
