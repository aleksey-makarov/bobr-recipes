let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkgconf_src =
    recipe.fetch "pkgconf-src-2.5.1" {
      url = "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz",
      hash = "md5:3291128c917fdb8fccd8c9e7784b643b",
    }
  in

  let pkgconf =
    recipe.binary "pkgconf-2.5.1" {
      script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/pkgconf-2.5.1",
        ],
        post_install = m%"
          ln -sv pkgconf "${MBUILD_INSTALL_DIR}/usr/bin/pkg-config"
          ln -sv pkgconf.1 "${MBUILD_INSTALL_DIR}/usr/share/man/man1/pkg-config.1"
        "%,
      },
    } pkgs.system_image_2 pkgs.buildscript_autotools [pkgconf_src]
  in

  {
    include [
      pkgconf_src,
      pkgconf,
    ],
  }
