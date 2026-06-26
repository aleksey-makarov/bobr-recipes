let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let psmisc_src = {
    name = "psmisc-src-23.7",
    tag = "Source",
    object_hash = "5e5c0580ad04e2eeabb5605f230d12dc9980742d3111cfa7df4cac72ffb98224",
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/psmisc/psmisc/psmisc-23.7.tar.xz",
        "https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz/download",
      ],
    },
  }
  in

  let psmisc = {
    name = "psmisc-23.7",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
      ],
    },
    config = {},
    inputs = {
      source = psmisc_src,
    },
  }
  in

  {
    include [
      psmisc,
    ],
  }
