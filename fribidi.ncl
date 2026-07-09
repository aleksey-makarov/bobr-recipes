# fribidi -- Unicode bidirectional algorithm, used by pango.
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "1.0.16" in
let default_hashes = {
  "1.0.16" = "d5c061bcfbbe2c11bc5d4505fa4545811a386e0d2ac02e5d4befb5ded52dd260",
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
