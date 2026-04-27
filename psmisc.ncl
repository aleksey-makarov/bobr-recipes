let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let psmisc_src = {
    name = "psmisc-src-23.7",
    tag = "Source",
    object_hash = "486e65b54d0e4d2a942e292e5185379cfd177b7cf780bf591ed5b9b6aab85a67",
    origin = {
      type = "http",
      url = [
        "https://downloads.sourceforge.net/project/psmisc/psmisc/psmisc-23.7.tar.xz",
        "https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz/download",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let psmisc = {
    name = "psmisc-23.7",
    tag = "Autotools",
    config = {},
    inputs = {
      image = pkgs.system_image,
      source = psmisc_src,
    },
  }
  in

  {
    include [
      psmisc_src,
      psmisc,
    ],
  }
