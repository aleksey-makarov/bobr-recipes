
fun pkgs =>
  let cairo_src = fun version => fun hash => {
    name = "cairo-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.cairographics.org/releases/cairo-%{version}.tar.xz",
    },
  }
  in

  # Used by Weston's desktop-shell and reference clients (panel, terminal). We
  # only need the image surface + freetype/fontconfig text; X11/glib/tests off.
  let cairo = {
    version | default = "1.18.4",
    source_object_hash | default = "445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb",
    name = "cairo-%{version}",
    tag = "MesonInstall",
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
      source = cairo_src version source_object_hash,
    },
  }
  in

  {
    include [
      cairo,
    ],
  }
