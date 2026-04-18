let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libtool_src =
    recipe.fetch "libtool-src-2.5.4" {
      url = [
        "https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz",
        "https://mirrors.kernel.org/gnu/libtool/libtool-2.5.4.tar.xz",
      ],
      hash = "md5:22e0a29df8af5fdde276ea3a7d351d30",
    }
  in

  let libtool =
    let script_config = {
        post_install = m%"
          rm -fv "${MBUILD_INSTALL_DIR}/usr/lib/libltdl.a"
        "%,
      }
    in
    recipe.binary "libtool-2.5.4" {
      include script_config,
    } pkgs.system_image pkgs.buildscript_autotools [libtool_src]
  in

  {
    include [
      libtool_src,
      libtool,
    ],
  }
