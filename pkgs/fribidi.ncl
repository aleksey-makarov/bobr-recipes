# fribidi -- Unicode bidirectional algorithm, used by pango.
# Configure version and hash through `pkgs.fribidi_src`.
fun pkgs =>
  let fribidi_src = {
    version | default = "1.0.16",
    name = "fribidi-src-%{version}",
    tag = "Source",
    object_hash | default = "1b1cde5b235d40479e91be2f0e88a309e3214c8ab470ec8a2744d82a5a9ea05c",
    origin = {
      tag = "Http",
      url = "https://github.com/fribidi/fribidi/releases/download/v%{version}/fribidi-%{version}.tar.xz",
    },
  }
  in

  let fribidi = {
    name = "fribidi-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddocs=false",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = pkgs.fribidi_src,
    },
  }
  in

  {
    include [
      fribidi_src,
      fribidi,
    ],
  }
