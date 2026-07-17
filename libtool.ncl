let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libtool_src = fun version => fun hash => {
    name = "libtool-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/libtool/libtool-%{version}.tar.xz",
        "https://mirrors.kernel.org/gnu/libtool/libtool-%{version}.tar.xz",
      ],
    },
  }
  in

  let libtool = {
    version | default = "2.5.4",
    source_object_hash | default = "f81f5860666b0bc7d84baddefa60d1cb9fa6fceb2398cc3baca6afaa60266675",
    name = "libtool-%{version}",
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
          "/usr/lib/libltdl.a",
        ],
      },
    },
    inputs = {
      source = libtool_src version source_object_hash,
    },
  }
  in

  {
    include [
      libtool,
    ],
  }
