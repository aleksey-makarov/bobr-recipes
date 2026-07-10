let version = "0.44.2" in

fun pkgs =>
  let pixman_src = {
    name = "pixman-src-%{version}",
    tag = "Source",
    object_hash = "6349061ce1a338ab6952b92194d1b0377472244208d47ff25bef86fc71973466",
    origin = {
      tag = "Http",
      url = "https://www.cairographics.org/releases/pixman-%{version}.tar.gz",
    },
  }
  in

  let pixman = {
    name = "pixman-%{version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dtests=disabled",
        "-Ddemos=disabled",
        "-Dgtk=disabled",
      ],
    },
    inputs = {
      source = pixman_src,
    },
  }
  in

  {
    include [
      pixman,
    ],
  }
