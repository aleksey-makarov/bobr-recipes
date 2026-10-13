# harfbuzz -- text shaping, used by pango/gtk4. Built with FreeType (hb-ft) and
# GLib/GObject + introspection; cairo/icu off (pango uses cairo directly, and
# hb-cairo would pull cairo->freetype into the graph). The dependency on
# freetype is one-directional (freetype is NOT rebuilt with harfbuzz -- that
# would create a mutual runtime dep, and harfbuzz-in-freetype only tweaks
# autohinting), so there is no cycle.
# Configure version and hash through `pkgs.harfbuzz_src`.
fun pkgs =>
  let harfbuzz_src = {
    version | default = "14.2.1",
    name = "harfbuzz-src-%{version}",
    tag = "Source",
    object_hash | default = "a54a5d8e9380a41fbb762ce367bcbf7704792dfca0d93f1bbca86c5a57902e0e",
    origin = {
      tag = "Http",
      url = "https://github.com/harfbuzz/harfbuzz/releases/download/%{version}/harfbuzz-%{version}.tar.xz",
    },
  }
  in

  let harfbuzz = {
    name = "harfbuzz-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.freetype,
        pkgs.glib,
        pkgs.gobject_introspection,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
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
      source = pkgs.harfbuzz_src,
    },
  }
  in

  {
    include [
      harfbuzz_src,
      harfbuzz,
    ],
  }
