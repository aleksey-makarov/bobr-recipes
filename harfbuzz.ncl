# harfbuzz -- text shaping, used by pango/gtk4. Built with FreeType (hb-ft) and
# GLib/GObject + introspection; cairo/icu off (pango uses cairo directly, and
# hb-cairo would pull cairo->freetype into the graph). The dependency on
# freetype is one-directional (freetype is NOT rebuilt with harfbuzz -- that
# would create a mutual runtime dep, and harfbuzz-in-freetype only tweaks
# autohinting), so there is no cycle. `version`/`hashes` are node fields
# (overridable), as in linux.ncl.
let default_version = "14.2.1" in
let default_hashes = {
  "14.2.1" = "476395a0571c374770c1f13ec80b16f56fd4664819c67cd35fd34f539eab9c0f",
}
in

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
    version | default = default_version,
    hashes | default = default_hashes,
    name = "harfbuzz-%{version}",
    tag = "Meson",
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
      source = mk_src version (hashes."%{version}"),
    },
  }
  in

  {
    include [
      harfbuzz,
    ],
  }
