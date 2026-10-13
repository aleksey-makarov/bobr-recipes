let recipe = import "../recipe-lib.ncl" in
# pango -- text layout, used by GTK4. Uses harfbuzz (shaping), fribidi (bidi),
# cairo (rendering), fontconfig/freetype (fonts). Xft off (no X).
# Configure version and hash through `pkgs.pango_src`.
let branch = recipe.version_prefix 2 in

fun pkgs =>
  let pango_src = {
    version | default = "1.56.4",
    name = "pango-src-%{version}",
    tag = "Source",
    object_hash | default = "17065e2fcc5f5a5bdbffc884c956bfc7c451a96e8c4fb2f8ad837c6413cb5a01",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/pango/%{branch version}/pango-%{version}.tar.xz",
    },
  }
  in

  let pango = {
    name = "pango-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.glib,
        pkgs.harfbuzz,
        pkgs.fribidi,
        pkgs.cairo,
        pkgs.fontconfig,
        pkgs.freetype,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.glib,
        pkgs.harfbuzz,
        pkgs.fribidi,
        pkgs.cairo,
        pkgs.fontconfig,
        pkgs.freetype,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dintrospection=enabled",
        "-Dxft=disabled",
        "-Dsysprof=disabled",
        "-Dlibthai=disabled",
        "-Dbuild-testsuite=false",
        "-Dbuild-examples=false",
        "-Ddocumentation=false",
        "-Dgtk_doc=false",
        "-Dman-pages=false",
      ],
    },
    inputs = {
      source = pkgs.pango_src,
    },
  }
  in

  {
    include [
      pango_src,
      pango,
    ],
  }
