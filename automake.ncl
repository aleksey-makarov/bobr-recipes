let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let automake_src = {
    name = "automake-src-1.18.1",
    tag = "Source",
    object_hash = "336ff971f77aa5347e1ec98348ab4baabe07ff23d36c4dd5065b584137c276e4",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/automake/automake-1.18.1.tar.xz",
        "https://mirrors.kernel.org/gnu/automake/automake-1.18.1.tar.xz",
      ],
    },
    meta = {},
  }
  in

  let automake = {
    name = "automake-1.18.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--docdir=/usr/share/doc/automake-1.18.1",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs,
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
