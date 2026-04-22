let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gperf_src = {
    name = "gperf-src-3.3",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/gperf/gperf-3.3.tar.gz",
        "https://mirrors.kernel.org/gnu/gperf/gperf-3.3.tar.gz",
      ],
      hash = "md5:31753b021ea78a21f154bf9eecb8b079",
    },
    inputs = {},
  }
  in

  let gperf = {
    name = "gperf-3.3",
    tag = "Autotools",
    config = {
      configure_args = ["--docdir=/usr/share/doc/gperf-3.3"],
    },
    inputs = {
      image = pkgs.system_image_2,
      source = gperf_src,
    },
  }
  in

  {
    include [
      gperf_src,
      gperf,
    ],
  }
