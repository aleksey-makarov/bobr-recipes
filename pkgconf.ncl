let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let pkgconf_src = {
    name = "pkgconf-src-2.5.1",
    tag = "Source",
    object_hash = "e711b652e2bba08164fa9073df53a11c284b6caae71431d30b5ca0eb28df0ae5",
    origin = {
      type = "http",
      url = "https://distfiles.ariadne.space/pkgconf/pkgconf-2.5.1.tar.xz",
      unpack = true,
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
