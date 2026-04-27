let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libtool_src = {
    name = "libtool-src-2.5.4",
    tag = "Source",
    object_hash = "5ac77ad72cf9663bd437fb91a597a69b9566c3422247f3f49c1c4ca7b5bc5aaf",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz",
        "https://mirrors.kernel.org/gnu/libtool/libtool-2.5.4.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let libtool = {
    name = "libtool-2.5.4",
    tag = "Autotools",
    config = {
      post_install = {
        name = "remove_static_libltdl",
        run_as = "root",
        argv = [
          "rm",
          "-fv",
          "@{out}/usr/lib/libltdl.a",
        ],
      },
    },
    inputs = {
      image = pkgs.system_image,
      source = libtool_src,
    },
  }
  in

  {
    include [
      libtool_src,
      libtool,
    ],
  }
