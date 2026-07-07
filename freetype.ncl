let version = "2.14.3" in

fun pkgs =>
  let freetype_src = {
    name = "freetype-src-%{version}",
    tag = "Source",
    object_hash = "7b91b5c1beeffb181834e9efa7fb704e1a195f045f8063708cd6384595c46a6b",
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/freetype/freetype-%{version}.tar.xz",
    },
  }
  in

  # harfbuzz is disabled to break the freetype<->harfbuzz cycle (we don't build
  # harfbuzz for the Weston bring-up); brotli off. png/zlib/bzip2 enabled.
  let freetype = {
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
      source = freetype_src,
    },
  }
  in

  {
    include [
      freetype,
    ],
  }
