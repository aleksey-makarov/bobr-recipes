let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

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
    build.build_autotools {
      name = "libtool-2.5.4",
      sources = [libtool_src],
      script_config = {
        post_install = m%"
          rm -fv "${MBUILD_INSTALL_DIR}/usr/lib/libltdl.a"
        "%,
      },
    }
  in

  {
    include [
      libtool_src,
      libtool,
    ],
  }
