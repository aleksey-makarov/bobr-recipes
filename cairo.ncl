let version = "1.18.4" in

fun pkgs =>
  let cairo_src = {
    name = "cairo-src-%{version}",
    tag = "Source",
    object_hash = "445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb",
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
        pkgs.glib,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.pixman,
        pkgs.freetype,
        pkgs.fontconfig,
        pkgs.libpng,
        pkgs.zlib,
        pkgs.glib,
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
        # cairo-gobject: needed by pango/GTK4. Was off for the Weston bring-up.
        "-Dglib=enabled",
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
