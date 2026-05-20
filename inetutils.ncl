let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let inetutils_src = {
    name = "inetutils-src-2.6",
    tag = "Source",
    object_hash = "2cd7031b5aec0a25df16cb66eeaf3a8c36693cbc086f9088cdfadbcb3822817f",
    origin = {
      type = "http",
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
    tag = "Autotools",
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
      post_install = {
        name = "move_ifconfig",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            mkdir -p "@{out}/usr/sbin"
            if [ -f "@{out}/usr/bin/ifconfig" ]; then
              mv -v "@{out}/usr/bin/ifconfig" "@{out}/usr/sbin/ifconfig"
            fi
          "%,
        ],
      },
    },
    inputs = {
      rootfs = inetutils_build_rootfs,
      source = inetutils_src,
    },
  }
  in

  {
    include [
      inetutils_src,
      inetutils,
    ],
  }
