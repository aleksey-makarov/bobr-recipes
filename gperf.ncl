let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let gperf_src =
    recipe.fetch "gperf-src-3.3" {
      url = [
        "https://ftp.gnu.org/gnu/gperf/gperf-3.3.tar.gz",
        "https://mirrors.kernel.org/gnu/gperf/gperf-3.3.tar.gz",
      ],
      hash = "md5:31753b021ea78a21f154bf9eecb8b079",
    }
  in

  let gperf =
    build.build_autotools {
      name = "gperf-3.3",
      sources = [gperf_src],
      script_config = {
        configure_args = ["--docdir=/usr/share/doc/gperf-3.3"],
      },
    }
  in

  {
    include [
      gperf_src,
      gperf,
    ],
  }
