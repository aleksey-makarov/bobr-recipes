let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let psmisc_src = {
    name = "psmisc-src-23.7",
    tag = "Fetch",
    config = {
      url = [
        "https://downloads.sourceforge.net/project/psmisc/psmisc/psmisc-23.7.tar.xz",
        "https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz/download",
      ],
      hash = "md5:53eae841735189a896d614cba440eb10",
    },
    inputs = {},
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
