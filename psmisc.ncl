let recipe = import "recipe-lib.ncl" in

fun pkgs =>
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
    let script_config = {}
    in
    recipe.binary "psmisc-23.7" {
      include script_config,
    } pkgs.system_image pkgs.buildscript_autotools [psmisc_src]
  in

  {
    include [
      psmisc_src,
      psmisc,
    ],
  }
