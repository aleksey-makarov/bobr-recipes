# libtiff -- TIFF codec. GTK4 links it directly for its GDK TIFF texture loader
# (png/tiff/jpeg loaders are built into gdk in GTK4, no toggle to skip tiff).
# Only zlib + jpeg codecs; other optional codecs and the C++ wrapper are off.
# Configure version and hash through `pkgs.libtiff_src`.
fun pkgs =>
  let libtiff_src = {
    version | default = "4.7.0",
    name = "libtiff-src-%{version}",
    tag = "Source",
    object_hash | default = "273a0a73b1f0bed640afee4a5df0337357ced5b53d3d5d1c405b936501f71017",
    origin = {
      tag = "Http",
      url = "https://download.osgeo.org/libtiff/tiff-%{version}.tar.xz",
    },
  }
  in

  let libtiff = {
    name = "libtiff-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.zlib,
        pkgs.libjpeg_turbo,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.libtiff_src,
    },
  }
  in

  {
    include [
      libtiff_src,
      libtiff,
    ],
  }
