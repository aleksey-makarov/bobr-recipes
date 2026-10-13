fun pkgs =>
  # Configure version and hash through pkgs.gperf_src.
  let gperf_src = {
    version | default = "3.3",
    name = "gperf-src-%{version}",
    tag = "Source",
    object_hash | default = "fd87e0aba7e43ae054837afd6cd4db03a3f2693deb3619085e6ed9d8d9604ad8",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/gperf/gperf-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/gperf/gperf-%{version}.tar.gz",
      ],
    },
  }
  in

  let gperf = {
    name = "gperf-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
      ],
    },
    config = {
      configure_args = ["--docdir=/usr/share/doc/gperf-%{inputs.source.version}"],
    },
    inputs = {
      source = pkgs.gperf_src,
    },
  }
  in

  {
    include [
      gperf,
      gperf_src,
    ],
  }
