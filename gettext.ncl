let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gettext_src = {
    name = "gettext-src-0.26",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/gettext/gettext-0.26.tar.xz",
        "https://mirrors.kernel.org/gnu/gettext/gettext-0.26.tar.xz",
      ],
      hash = "md5:8e14e926f088e292f5f2bce95b81d10e",
    },
    inputs = {},
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
          "${out}/usr/lib/preloadable_libintl.so",
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
