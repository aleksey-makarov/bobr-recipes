let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libtool_src = {
    name = "libtool-src-2.5.4",
    tag = "Source",
    object_hash = "86809ac951117f8fca83a874ba87a61a348447a2788c27a84df0041fc315a670",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/libtool/libtool-2.5.4.tar.xz",
        "https://mirrors.kernel.org/gnu/libtool/libtool-2.5.4.tar.xz",
      ],
    },
  }
  in

  let libtool = {
    name = "libtool-2.5.4",
    tag = "AutotoolsPackage",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc,
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
      libtool_src,
      libtool,
    ],
  }
