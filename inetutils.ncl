let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let inetutils_src =
    {
      name = "inetutils-src-2.6",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/inetutils/inetutils-2.6.tar.xz",
        "https://mirrors.kernel.org/gnu/inetutils/inetutils-2.6.tar.xz",
      ],
      hash = "md5:401d7d07682a193960bcdecafd03de94",
      },
      inputs = {},
    }
  in

  let inetutils_build_image =
    recipe.image "inetutils-build-image" {} pkgs.system_image_2 [
      pkgs.ncurses,
    ]
  in

  let inetutils =
    recipe.binary "inetutils-2.6" {
      script_config = {
        pre_configure = m%"
          sed -i 's/def HAVE_TERMCAP_TGETENT/ 1/' telnet/telnet.c
        "%,
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
        post_install = m%"
          mkdir -p "${MBUILD_INSTALL_DIR}/usr/sbin"
          if [ -f "${MBUILD_INSTALL_DIR}/usr/bin/ifconfig" ]; then
            mv -v "${MBUILD_INSTALL_DIR}/usr/bin/ifconfig" "${MBUILD_INSTALL_DIR}/usr/sbin/ifconfig"
          fi
        "%,
      },
    } inetutils_build_image pkgs.buildscript_autotools [inetutils_src]
  in

  {
    include [
      inetutils_src,
      inetutils,
    ],
  }
