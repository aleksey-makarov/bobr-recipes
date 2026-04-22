let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkgconf_src = {
    name = "pkgconf-src-2.5.1",
    tag = "Fetch",
    config = {
      url = "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz",
      hash = "md5:3291128c917fdb8fccd8c9e7784b643b",
    },
    inputs = {},
  }
  in

  let pkgconf = {
    name = "pkgconf-2.5.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/pkgconf-2.5.1",
      ],
      post_install = [
        {
          name = "link_pkg_config",
          run_as = "root",
          argv = [
            "ln",
            "-sv",
            "pkgconf",
            "@{out}/usr/bin/pkg-config",
          ],
        },
        {
          name = "link_pkg_config_manpage",
          run_as = "root",
          argv = [
            "ln",
            "-sv",
            "pkgconf.1",
            "@{out}/usr/share/man/man1/pkg-config.1",
          ],
        },
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      source = pkgconf_src,
    },
  }
  in

  {
    include [
      pkgconf_src,
      pkgconf,
    ],
  }
