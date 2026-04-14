let recipe = import "recipe-lib.ncl" in
let build = import "build-lib.ncl" in

fun pkgs =>
  let procps_ng_src =
    recipe.fetch "procps-ng-src-4.0.5" {
      url = [
        "https://downloads.sourceforge.net/project/procps-ng/Production/procps-ng-4.0.5.tar.xz",
        "https://sourceforge.net/projects/procps-ng/files/Production/procps-ng-4.0.5.tar.xz/download",
      ],
      hash = "md5:90803e64f51f192f3325d25c3335d057",
    }
  in

  let procps_ng =
    (build pkgs).build_autotools {
      name = "procps-ng-4.0.5",
      sources = [procps_ng_src],
      script_config = {
        configure_args = [
          "--docdir=/usr/share/doc/procps-ng-4.0.5",
          "--disable-static",
          "--disable-kill",
          "--enable-watch8bit",
        ],
      },
    }
  in

  {
    include [
      procps_ng_src,
      procps_ng,
    ],
  }
