let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gperf_src = {
    name = "gperf-src-3.3",
    tag = "Source",
    object_hash = "b18ef3b0a49a9935762246937439b9ec7dd708d1ad37672ff8a7d5a07f5027cc",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gperf/gperf-3.3.tar.gz",
        "https://mirrors.kernel.org/gnu/gperf/gperf-3.3.tar.gz",
      ],
    },
  }
  in

  let gperf = {
    name = "gperf-3.3",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--docdir=/usr/share/doc/gperf-3.3"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = gperf_src,
    },
  }
  in

  {
    include [
      gperf,
    ],
  }
