
fun pkgs =>
  let pixman_src = fun version => fun hash => {
    name = "pixman-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.cairographics.org/releases/pixman-%{version}.tar.gz",
    },
  }
  in

  let pixman = {
    version | default = "0.44.2",
    source_object_hash | default = "6349061ce1a338ab6952b92194d1b0377472244208d47ff25bef86fc71973466",
    name = "pixman-%{version}",
    tag = "MesonInstall",
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
      source = pixman_src version source_object_hash,
    },
  }
  in

  {
    include [
      pixman,
    ],
  }
