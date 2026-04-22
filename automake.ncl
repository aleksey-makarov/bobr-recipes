let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let automake_src = {
    name = "automake-src-1.18.1",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/automake/automake-1.18.1.tar.xz",
        "https://mirrors.kernel.org/gnu/automake/automake-1.18.1.tar.xz",
      ],
      hash = "md5:cea31dbf1120f890cbf2a3032cfb9a68",
    },
    inputs = {},
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
      image = pkgs.system_image,
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
