let version = "1.18.4" in

fun pkgs =>
  let cairo_src = {
    name = "cairo-src-%{version}",
    tag = "Source",
    object_hash = "6d1d88794f7cc0275dcef05703e675eeb119eaa4c14b7ba7118125cac668daf0",
    origin = {
      tag = "Http",
      url = "https://www.cairographics.org/releases/cairo-%{version}.tar.xz",
    },
  }
  in

  # Used by Weston's desktop-shell and reference clients (panel, terminal). We
  # only need the image surface + freetype/fontconfig text; X11/glib/tests off.
  let cairo = {
    name = "cairo-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.pixman,
        pkgs.freetype,
        pkgs.fontconfig,
        pkgs.libpng,
        pkgs.zlib,
        pkgs.expat,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.pixman,
        pkgs.freetype,
        pkgs.fontconfig,
        pkgs.libpng,
        pkgs.zlib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "--wrap-mode=nodownload",
        "-Dtests=disabled",
        "-Dxlib=disabled",
        "-Dxcb=disabled",
        "-Dglib=disabled",
        "-Dtee=disabled",
        "-Dsymbol-lookup=disabled",
        "-Dspectre=disabled",
        "-Dfreetype=enabled",
        "-Dfontconfig=enabled",
        "-Dpng=enabled",
        "-Dzlib=enabled",
      ],
    },
    inputs = {
      source = cairo_src,
    },
  }
  in

  {
    include [
      cairo,
    ],
  }
