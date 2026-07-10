# fribidi -- Unicode bidirectional algorithm, used by pango.
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "1.0.16" in
let default_hashes = {
  "1.0.16" = "1b1cde5b235d40479e91be2f0e88a309e3214c8ab470ec8a2744d82a5a9ea05c",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "fribidi-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/fribidi/fribidi/releases/download/v%{version}/fribidi-%{version}.tar.xz",
        },
      }
  in

  let fribidi = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "fribidi-%{version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      fribidi,
    ],
  }
