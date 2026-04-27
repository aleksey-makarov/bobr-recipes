let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gperf_src = {
    name = "gperf-src-3.3",
    tag = "Source",
    object_hash = "1039eb65925cb2addf9c7513d7c2c4f73de6fab57e40ceacebd30ff4ab92ec6a",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gperf/gperf-3.3.tar.gz",
        "https://mirrors.kernel.org/gnu/gperf/gperf-3.3.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
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
