# Little CMS 2 -- color management engine, needed by colord and mutter. Core
# library only (jpeg/tiff/zlib utilities off, no external deps). `version`/
# `hashes` are node fields (overridable), as in linux.ncl.
let default_version = "2.17" in
let default_hashes = {
  "2.17" = "d11af569e42a1baa1650d20ad61d12e41af4fead4aa7964a01f93b08b53ab074",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "lcms2-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/mm2/Little-CMS/releases/download/lcms%{version}/lcms2-%{version}.tar.gz",
        },
      }
  in

  let lcms2 = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "lcms2-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--without-jpeg",
        "--without-tiff",
        "--without-zlib",
      ],
    },
    inputs = {
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      lcms2,
    ],
  }
