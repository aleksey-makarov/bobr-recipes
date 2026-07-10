let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gperf_src = {
    name = "gperf-src-3.3",
    tag = "Source",
    object_hash = "fd87e0aba7e43ae054837afd6cd4db03a3f2693deb3619085e6ed9d8d9604ad8",
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
