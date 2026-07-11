let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let psmisc_src = fun version => fun hash => {
    name = "psmisc-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://downloads.sourceforge.net/project/psmisc/psmisc/psmisc-%{version}.tar.xz",
        "https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-%{version}.tar.xz/download",
      ],
    },
  }
  in

  let psmisc = {
    version | default = "23.7",
    source_object_hash | default = "58c55d9c1402474065adae669511c191de374b0871eec781239ab400b907c327",
    name = "psmisc-%{version}",
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
      source = psmisc_src version source_object_hash,
    },
  }
  in

  {
    include [
      psmisc,
    ],
  }
