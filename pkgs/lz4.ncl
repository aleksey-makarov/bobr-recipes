fun pkgs =>
  let lz4_src = {
    version | default = "1.10.0",
    name = "lz4-src-%{version}",
    tag = "Source",
    object_hash | default = "537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b",
    origin = {
      tag = "Http",
      url = "https://github.com/lz4/lz4/releases/download/v%{version}/lz4-%{version}.tar.gz",
    },
  }
  in

  let lz4 = {
    name = "lz4-%{inputs.source.version}",
    tag = "Makefile",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      make_args = [
        "BUILD_STATIC=no",
        "PREFIX=/usr",
      ],
    },
    inputs = {
      source = pkgs.lz4_src,
    },
  }
  in

  {
    include [
      lz4_src,
      lz4,
    ],
  }
