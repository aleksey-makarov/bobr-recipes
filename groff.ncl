let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let groff_src = {
    name = "groff-src-1.23.0",
    tag = "Source",
    object_hash = "df2a48401b960e3b5ea5d17bac0c77e563b87aa49dc09d6a173efba713d8d8f7",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz",
        "https://mirrors.kernel.org/gnu/groff/groff-1.23.0.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
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
