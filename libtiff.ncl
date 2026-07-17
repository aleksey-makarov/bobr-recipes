# libtiff -- TIFF codec. GTK4 links it directly for its GDK TIFF texture loader
# (png/tiff/jpeg loaders are built into gdk in GTK4, no toggle to skip tiff).
# Only zlib + jpeg codecs; other optional codecs and the C++ wrapper are off.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

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
    version | default = "4.7.0",
    source_object_hash | default = "273a0a73b1f0bed640afee4a5df0337357ced5b53d3d5d1c405b936501f71017",
    name = "libtiff-%{version}",
    tag = "AutotoolsInstall",
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libtiff,
    ],
  }
