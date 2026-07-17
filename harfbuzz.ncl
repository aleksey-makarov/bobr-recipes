# harfbuzz -- text shaping, used by pango/gtk4. Built with FreeType (hb-ft) and
# GLib/GObject + introspection; cairo/icu off (pango uses cairo directly, and
# hb-cairo would pull cairo->freetype into the graph). The dependency on
# freetype is one-directional (freetype is NOT rebuilt with harfbuzz -- that
# would create a mutual runtime dep, and harfbuzz-in-freetype only tweaks
# autohinting), so there is no cycle. `version`/`source_object_hash` are node fields
# (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "harfbuzz-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/harfbuzz/harfbuzz/releases/download/%{version}/harfbuzz-%{version}.tar.xz",
        },
      }
  in

  let harfbuzz = {
    version | default = "14.2.1",
    source_object_hash | default = "a54a5d8e9380a41fbb762ce367bcbf7704792dfca0d93f1bbca86c5a57902e0e",
    name = "harfbuzz-%{version}",
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.freetype,
        pkgs.glib,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.freetype,
        pkgs.glib,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dfreetype=enabled",
        "-Dglib=enabled",
        "-Dgobject=enabled",
        "-Dcairo=disabled",
        "-Dicu=disabled",
        "-Dintrospection=enabled",
        "-Dtests=disabled",
        "-Ddocs=disabled",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      harfbuzz,
    ],
  }
