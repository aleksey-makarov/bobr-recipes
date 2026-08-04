fun pkgs =>
  let lz4_src = fun version => fun hash => {
    name = "lz4-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/lz4/lz4/releases/download/v%{version}/lz4-%{version}.tar.gz",
    },
  }
  in

  let lz4 = {
    version | default = "1.10.0",
    source_object_hash | default = "537512904744b35e232912055ccf8ec66d768639ff3abe5788d90d792ec5f48b",
    name = "lz4-%{version}",
    tag = "Makefile",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      make_args = [
        "BUILD_STATIC=no",
        "PREFIX=/usr",
      ],
    },
    inputs = {
      source = lz4_src version source_object_hash,
    },
  }
  in

  {
    include [
      lz4,
    ],
  }
