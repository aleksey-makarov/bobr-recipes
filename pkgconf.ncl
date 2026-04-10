let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let pkgconf_src =
    recipe.fetch "pkgconf-src-2.5.1" {
      url = "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz",
      hash = "md5:3291128c917fdb8fccd8c9e7784b643b",
    }
  in

  let pkgconf =
    build.build_autotools {
      name = "pkgconf-2.5.1",
      sources = [pkgconf_src],
      script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/pkgconf-2.5.1",
        ],
        post_install = m%"
          ln -sv pkgconf "/out/${out}/usr/bin/pkg-config"
          ln -sv pkgconf.1 "/out/${out}/usr/share/man/man1/pkg-config.1"
        "%,
      },
    }
  in

  {
    include [
      pkgconf_src,
      pkgconf,
    ],
  }
