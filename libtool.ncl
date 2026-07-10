let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libtool_src = {
    name = "libtool-src-2.5.4",
    tag = "Source",
    object_hash = "f81f5860666b0bc7d84baddefa60d1cb9fa6fceb2398cc3baca6afaa60266675",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz",
        "https://mirrors.kernel.org/gnu/libtool/libtool-2.5.4.tar.xz",
      ],
    },
  }
  in

  let libtool = {
    name = "libtool-2.5.4",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.bash,
        pkgs.coreutils,
        pkgs.sed,
        pkgs.grep,
        pkgs.autoconf,
        pkgs.m4,
      ],
    },
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
      source = libtool_src,
    },
  }
  in

  {
    include [
      libtool,
    ],
  }
