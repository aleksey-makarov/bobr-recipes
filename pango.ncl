let recipe = import "recipe-lib.ncl" in
# pango -- text layout, used by GTK4. Uses harfbuzz (shaping), fribidi (bidi),
# cairo (rendering), fontconfig/freetype (fonts). Xft off (no X).
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

let branch = recipe.version_prefix 2 in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "pango-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/pango/%{branch version}/pango-%{version}.tar.xz",
        },
      }
  in

  let pango = {
    version | default = "1.56.4",
    source_object_hash | default = "17065e2fcc5f5a5bdbffc884c956bfc7c451a96e8c4fb2f8ad837c6413cb5a01",
    name = "pango-%{version}",
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
        pkgs.glibc_libs,
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      pango,
    ],
  }
