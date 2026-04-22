let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let groff_src = {
    name = "groff-src-1.23.0",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz",
        "https://mirrors.kernel.org/gnu/groff/groff-1.23.0.tar.gz",
      ],
      hash = "md5:5e4f40315a22bb8a158748e7d5094c7d",
    },
    inputs = {},
  }
  in

  let groff = {
    name = "groff-1.23.0",
    tag = "Autotools",
    config = {
      env = {
        PAGE = "A4",
      },
    },
    inputs = {
      image = pkgs.system_image,
      source = groff_src,
    },
  }
  in

  {
    include [
      groff_src,
      groff,
    ],
  }
