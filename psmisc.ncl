let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let psmisc_src = {
    name = "psmisc-src-23.7",
    tag = "Source",
    object_hash = "58c55d9c1402474065adae669511c191de374b0871eec781239ab400b907c327",
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
