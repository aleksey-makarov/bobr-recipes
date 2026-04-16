let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let gettext_src =
    recipe.fetch "gettext-src-0.26" {
      url = [
        "https://ftp.gnu.org/gnu/gettext/gettext-0.26.tar.xz",
        "https://mirrors.kernel.org/gnu/gettext/gettext-0.26.tar.xz",
      ],
      hash = "md5:8e14e926f088e292f5f2bce95b81d10e",
    }
  in

  let gettext =
    build.build_autotools {
      name = "gettext-0.26",
      sources = [gettext_src],
      script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/gettext-0.26",
        ],
        post_install = "chmod -v 0755 \"${MBUILD_INSTALL_DIR}/usr/lib/preloadable_libintl.so\"",
      },
    }
  in

  {
    include [
      gettext_src,
      gettext,
    ],
  }
