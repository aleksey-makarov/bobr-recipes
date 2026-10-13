fun pkgs =>
  let pixman_src = {
    version | default = "0.44.2",
    name = "pixman-src-%{version}",
    tag = "Source",
    object_hash | default = "6349061ce1a338ab6952b92194d1b0377472244208d47ff25bef86fc71973466",
    origin = {
      tag = "Http",
      url = [
        "https://www.cairographics.org/releases/pixman-%{version}.tar.gz",
        "https://downloads.yoctoproject.org/mirror/sources/pixman-%{version}.tar.gz",
      ],
    },
  }
  in

  let pixman = {
    name = "pixman-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.pixman_src,
    },
  }
  in

  {
    include [
      pixman_src,
      pixman,
    ],
  }
