
fun pkgs =>
  let freetype_src = fun version => fun hash => {
    name = "freetype-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      # SourceForge is freetype's other upstream home. Use the canonical project
      # path, as the other SF-hosted recipes do: the short
      # downloads.sourceforge.net/freetype/ form serves an HTML interstitial the
      # downloader can save by mistake.
      url = [
        "https://download.savannah.gnu.org/releases/freetype/freetype-%{version}.tar.xz",
        "https://downloads.sourceforge.net/project/freetype/freetype2/%{version}/freetype-%{version}.tar.xz",
        "https://sourceforge.net/projects/freetype/files/freetype2/%{version}/freetype-%{version}.tar.xz/download",
        "https://tarballs.nixos.org/sha256/%{hash}",
      ],
    },
  }
  in

  # harfbuzz is disabled to break the freetype<->harfbuzz cycle (we don't build
  # harfbuzz for the Weston bring-up); brotli off. png/zlib/bzip2 enabled.
  let freetype = {
    version | default = "2.14.3",
    source_object_hash | default = "36bc4f1cc413335368ee656c42afca65c5a3987e8768cc28cf11ba775e785a5f",
    name = "freetype-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.zlib,
        pkgs.libpng,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.zlib,
        pkgs.libpng,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "--wrap-mode=nodownload",
        "-Dharfbuzz=disabled",
        "-Dbrotli=disabled",
        "-Dpng=enabled",
        "-Dzlib=system",
        # bzip2 ships no pkg-config file, so with --wrap-mode=nodownload it
        # can't be found; it is only needed for bzip2-compressed PCF fonts,
        # which we don't use (TTF only).
        "-Dbzip2=disabled",
      ],
    },
    inputs = {
      source = freetype_src version source_object_hash,
    },
  }
  in

  {
    include [
      freetype,
    ],
  }
