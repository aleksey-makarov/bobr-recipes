fun pkgs =>
  let libtool_src = {
    version | default = "2.5.4",
    name = "libtool-src-%{version}",
    tag = "Source",
    object_hash | default = "f81f5860666b0bc7d84baddefa60d1cb9fa6fceb2398cc3baca6afaa60266675",
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
    name = "libtool-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libtool_src,
    },
  }
  in

  {
    include [
      libtool_src,
      libtool,
    ],
  }
