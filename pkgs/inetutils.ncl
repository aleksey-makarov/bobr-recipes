fun pkgs =>
  let inetutils_src = {
    version | default = "2.6",
    name = "inetutils-src-%{version}",
    tag = "Source",
    object_hash | default = "68bedbfeaf73f7d86be2a7d99bcfbd4093d829f52770893919ae174c0b2357ca",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/inetutils/inetutils-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/inetutils/inetutils-%{version}.tar.xz",
      ],
    },
  }
  in

  let inetutils = {
    name = "inetutils-%{inputs.source.version}",
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
        name = "patch_telnet",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c",
        ],
      },
      # telnet uses both curses (cbreak, in libncursesw) and termcap (tgetent,
      # now split into libtinfo by our ncurses --with-termlib build). Its
      # configure only picks up the termcap library, so force both onto the link
      # line; --as-needed drops the unused ones from the non-telnet tools.
      env = { LIBS = "-lncursesw -ltinfo" },
      configure_args = [
        "--bindir=/usr/bin",
        "--localstatedir=/var",
        "--disable-logger",
        "--disable-whois",
        "--disable-rcp",
        "--disable-rexec",
        "--disable-rlogin",
        "--disable-rsh",
        "--disable-servers",
      ],
    },
    inputs = {
      source = pkgs.inetutils_src,
    },
  }
  in

  {
    include [
      inetutils_src,
      inetutils,
    ],
  }
