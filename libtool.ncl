let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libtool_src = {
    name = "libtool-src-2.5.4",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz",
        "https://mirrors.kernel.org/gnu/libtool/libtool-2.5.4.tar.xz",
      ],
      hash = "md5:22e0a29df8af5fdde276ea3a7d351d30",
    },
    inputs = {},
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
          "${out}/usr/lib/libltdl.a",
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
