fun pkgs =>
  # Configure version and hash through pkgs.expat_src.
  let expat_src = {
    version | default = "2.8.2",
    name = "expat-src-%{version}",
    tag = "Source",
    object_hash | default = "3ad89b8588e6644bd4e49981480d48b21289eebbcd4f0a1a4afb1c29f99b6ab4",
    origin =
      let release_tag = "R_" ++ std.string.replace "." "_" version in
      {
        tag = "Http",
        url = "https://github.com/libexpat/libexpat/releases/download/%{release_tag}/expat-%{version}.tar.xz",
      },
  }
  in

  let expat = {
    name = "expat-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/expat-%{inputs.source.version}",
      ],
    },
    inputs = {
      source = pkgs.expat_src,
    },
  }
  in

  {
    include [
      expat,
      expat_src,
    ],
  }
