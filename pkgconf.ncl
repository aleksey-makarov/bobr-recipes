let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkgconf_src = {
    name = "pkgconf-src-2.5.1",
    tag = "Source",
    object_hash = "cff856e6799a70d5a236c4b5761fd37be48acf1ad5f39a3c2d1aa93a5081abfc",
    origin = {
      type = "http",
      url = "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz",
    },
    meta = {},
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
