let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gettext_src =
    {
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

  let gettext =
    let script_config = {
        configure_args = [
          "--disable-static",
          "--docdir=/usr/share/doc/gettext-0.26",
        ],
        post_install = "chmod -v 0755 \"${MBUILD_INSTALL_DIR}/usr/lib/preloadable_libintl.so\"",
      }
    in
    recipe.binary "gettext-0.26" {
      include script_config,
    } pkgs.system_image pkgs.buildscript_autotools [gettext_src]
  in

  {
    include [
      gettext_src,
      gettext,
    ],
  }
