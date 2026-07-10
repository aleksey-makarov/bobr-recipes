let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let inetutils_src = {
    name = "inetutils-src-2.6",
    tag = "Source",
    object_hash = "68bedbfeaf73f7d86be2a7d99bcfbd4093d829f52770893919ae174c0b2357ca",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/inetutils/inetutils-2.6.tar.xz",
        "https://mirrors.kernel.org/gnu/inetutils/inetutils-2.6.tar.xz",
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
    name = "inetutils-2.6",
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
      source = inetutils_src,
    },
  }
  in

  {
    include [
      inetutils,
    ],
  }
