let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let psmisc_src =
    recipe.fetch "psmisc-src-23.7" {
      url = [
        "https://downloads.sourceforge.net/project/psmisc/psmisc/psmisc-23.7.tar.xz",
        "https://sourceforge.net/projects/psmisc/files/psmisc/psmisc-23.7.tar.xz/download",
      ],
      hash = "md5:53eae841735189a896d614cba440eb10",
    }
  in

  let psmisc =
    build.build_autotools {
      name = "psmisc-23.7",
      sources = [psmisc_src],
      script_config = {},
    }
  in

  {
    include [
      psmisc_src,
      psmisc,
    ],
  }
