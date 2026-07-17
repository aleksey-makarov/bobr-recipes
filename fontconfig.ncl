
fun pkgs =>
  let fontconfig_src = fun version => fun hash => {
    name = "fontconfig-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.freedesktop.org/software/fontconfig/release/fontconfig-%{version}.tar.xz",
    },
  }
  in

  let fontconfig = {
    version | default = "2.16.0",
    source_object_hash | default = "6a33dc555cc9ba8b10caf7695878ef134eeb36d0af366041f639b1da9b6ed220",
    name = "fontconfig-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.freetype,
        pkgs.expat,
        pkgs.gperf,
      ],
      runtime = [
        pkgs.glibc_libs,
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
      source = fontconfig_src version source_object_hash,
    },
  }
  in

  {
    include [
      fontconfig,
    ],
  }
