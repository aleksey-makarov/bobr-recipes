let version = "2.16.0" in

fun pkgs =>
  let fontconfig_src = {
    name = "fontconfig-src-%{version}",
    tag = "Source",
    object_hash = "c1acf7a62162e61cd3ebefe5fca445680e8f7f955361c5ffb513d86b4736f67a",
    origin = {
      tag = "Http",
      url = "https://www.freedesktop.org/software/fontconfig/release/fontconfig-%{version}.tar.xz",
    },
  }
  in

  let fontconfig = {
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
      source = fontconfig_src,
    },
  }
  in

  {
    include [
      fontconfig,
    ],
  }
