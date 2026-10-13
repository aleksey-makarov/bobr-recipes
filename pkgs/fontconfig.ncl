fun pkgs =>
  let fontconfig_src = {
    version | default = "2.16.0",
    name = "fontconfig-src-%{version}",
    tag = "Source",
    object_hash | default = "6a33dc555cc9ba8b10caf7695878ef134eeb36d0af366041f639b1da9b6ed220",
    origin = {
      tag = "Http",
      url = [
        "https://www.freedesktop.org/software/fontconfig/release/fontconfig-%{version}.tar.xz",
        "https://sources.buildroot.net/fontconfig/fontconfig-%{version}.tar.xz",
      ],
    },
  }
  in

  let fontconfig = {
    name = "fontconfig-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.freetype,
        pkgs.expat,
        pkgs.gperf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.freetype,
        pkgs.expat,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddoc=disabled",
        "-Dtests=disabled",
      ],
    },
    inputs = {
      source = pkgs.fontconfig_src,
    },
  }
  in

  {
    include [
      fontconfig_src,
      fontconfig,
    ],
  }
