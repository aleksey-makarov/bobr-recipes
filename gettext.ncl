let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gettext_src = {
    name = "gettext-src-0.26",
    tag = "Source",
    object_hash = "f601d9cd3fd141e65e1baf6e222de3b9b94fdc139eca58aa707f3f30bd080c00",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gettext/gettext-0.26.tar.xz",
        "https://mirrors.kernel.org/gnu/gettext/gettext-0.26.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let gettext = {
    name = "gettext-0.26",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/gettext-0.26",
      ],
      post_install = {
        name = "fix_preloadable_libintl_permissions",
        run_as = "root",
        argv = [
          "chmod",
          "-v",
          "0755",
          "@{out}/usr/lib/preloadable_libintl.so",
        ],
      },
    },
    inputs = {
      image = pkgs.system_image,
      source = gettext_src,
    },
  }
  in

  {
    include [
      gettext_src,
      gettext,
    ],
  }
