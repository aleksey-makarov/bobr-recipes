fun pkgs =>
  let gperf_src = fun version => fun hash => {
    name = "gperf-src-%{version}",
    tag = "Source",
    object_hash = hash,
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
    version | default = "3.3",
    source_object_hash | default = "fd87e0aba7e43ae054837afd6cd4db03a3f2693deb3619085e6ed9d8d9604ad8",
    name = "gperf-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      configure_args = ["--docdir=/usr/share/doc/gperf-%{version}"],
    },
    inputs = {
      source = gperf_src version source_object_hash,
    },
  }
  in

  {
    include [
      gperf,
    ],
  }
