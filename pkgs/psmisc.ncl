fun pkgs =>
  let psmisc_src = {
    version | default = "23.7",
    name = "psmisc-src-%{version}",
    tag = "Source",
    object_hash | default = "58c55d9c1402474065adae669511c191de374b0871eec781239ab400b907c327",
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
    name = "psmisc-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.ncurses_libs,
      ],
    },
    config = {},
    inputs = {
      source = pkgs.psmisc_src,
    },
  }
  in

  {
    include [
      psmisc_src,
      psmisc,
    ],
  }
