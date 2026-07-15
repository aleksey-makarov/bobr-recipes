let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let inetutils_src = fun version => fun hash => {
    name = "inetutils-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/inetutils/inetutils-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/inetutils/inetutils-%{version}.tar.xz",
      ],
    },
  }
  in

  let inetutils_build_rootfs = {
    name = "inetutils-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.ncurses,
      ],
  }
  in

  let inetutils = {
    version | default = "2.6",
    source_object_hash | default = "68bedbfeaf73f7d86be2a7d99bcfbd4093d829f52770893919ae174c0b2357ca",
    name = "inetutils-%{version}",
    tag = "AutotoolsRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
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
      _rootfs = inetutils_build_rootfs,
      source = inetutils_src version source_object_hash,
    },
  }
  in

  {
    include [
      inetutils,
    ],
  }
