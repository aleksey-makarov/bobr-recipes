let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let automake_src = {
    name = "automake-src-1.18.1",
    tag = "Source",
    object_hash = "ffa05fcb79316474182f9f80b782dcaf83cc72a5782e4f5525488b7de9f2f514",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/automake/automake-1.18.1.tar.xz",
        "https://mirrors.kernel.org/gnu/automake/automake-1.18.1.tar.xz",
      ],
      unpack = true,
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
