let version = "0.44.2" in

fun pkgs =>
  let pixman_src = {
    name = "pixman-src-%{version}",
    tag = "Source",
    object_hash = "e1a1d46be6004e84702d0662e7a935ecb838151a142b741e429f36c9a03ba49e",
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
