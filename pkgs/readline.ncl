fun pkgs =>
  # Configure version and hash through pkgs.readline_src.
  let readline_src = {
    version | default = "8.3",
    name = "readline-src-%{version}",
    tag = "Source",
    object_hash | default = "fe5383204467828cd495ee8d1d3c037a7eba1389c22bc6a041f627976f9061cc",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/readline/readline-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/readline/readline-%{version}.tar.gz",
      ],
    },
  }
  in

  let readline = {
    name = "readline-%{inputs.source.version}",
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
    config = {
      pre_configure = {
        name = "patch_readline_build",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            sed -i '/MV.*old/d' Makefile.in
            sed -i '/{OLDSUFF}/c:' support/shlib-install
            sed -i 's/-Wl,-rpath,[^ ]*//' support/shobj-conf
          "%,
        ],
      },
      configure_args = [
        "--disable-static",
        "--with-curses",
        "--docdir=/usr/share/doc/readline-%{inputs.source.version}",
      ],
      # Link libreadline.so against libtinfo (the terminfo/termcap routines live
      # there now that ncurses is built --with-termlib=tinfo), so the shared
      # library is self-contained: consumers such as nmcli that link -lreadline
      # without also linking curses resolve tgetent/tputs through it. This must
      # be a make command-line assignment: the Makefile sets SHLIB_LIBS itself
      # (from configure), which would override the same name inherited from env.
      make_args = ["SHLIB_LIBS=-ltinfo"],
    },
    inputs = {
      source = pkgs.readline_src,
    },
  }
  in

  {
    include [
      readline,
      readline_src,
    ],
  }
