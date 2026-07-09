# libtiff -- TIFF codec. GTK4 links it directly for its GDK TIFF texture loader
# (png/tiff/jpeg loaders are built into gdk in GTK4, no toggle to skip tiff).
# Only zlib + jpeg codecs; other optional codecs and the C++ wrapper are off.
# `version`/`hashes` are node fields (overridable), as in linux.ncl.
let default_version = "4.7.0" in
let default_hashes = {
  "4.7.0" = "ced827b8165f939f5bcf369b53e52ab003406e84e15a3d53773f332dfe81151d",
}
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libtiff-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.osgeo.org/libtiff/tiff-%{version}.tar.xz",
        },
      }
  in

  let libtiff = {
    version | default = default_version,
    hashes | default = default_hashes,
    name = "libtiff-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.zlib,
        pkgs.libjpeg_turbo,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
        pkgs.libjpeg_turbo,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
        "--enable-zlib",
        "--enable-jpeg",
        "--disable-old-jpeg",
        "--disable-lzma",
        "--disable-zstd",
        "--disable-webp",
        "--disable-jbig",
        "--disable-lerc",
        "--disable-libdeflate",
        "--disable-cxx",
      ],
    },
    inputs = {
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      libtiff,
    ],
  }
