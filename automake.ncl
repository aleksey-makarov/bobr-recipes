let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let automake_src = {
    name = "automake-src-1.18.1",
    tag = "Source",
    object_hash = "336ff971f77aa5347e1ec98348ab4baabe07ff23d36c4dd5065b584137c276e4",
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
      automake_src,
      automake,
    ],
  }
