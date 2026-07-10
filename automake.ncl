let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let automake_src = {
    name = "automake-src-1.18.1",
    tag = "Source",
    object_hash = "168aa363278351b89af56684448f525a5bce5079d0b6842bd910fdd3f1646887",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/automake/automake-1.18.1.tar.xz",
        "https://mirrors.kernel.org/gnu/automake/automake-1.18.1.tar.xz",
      ],
    },
  }
  in

  let automake = {
    name = "automake-1.18.1",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.autoconf,
        pkgs.m4,
        pkgs.perl,
      ],
    },
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/automake-1.18.1",
      ],
    },
    inputs = {
      source = automake_src,
    },
  }
  in

  {
    include [
      automake,
    ],
  }
