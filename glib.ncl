# GLib / GObject / GIO -- the base of the GNOME stack. Built in two passes to
# break the glib <-> gobject-introspection cycle:
#   glib_gen1 (introspection off) -> gobject-introspection -> glib (gir on).
# Downstream uses `glib` (has the GLib/GObject/Gio typelibs). `version`/`hashes`
# are node fields (overridable), as in linux.ncl.
let default_version = "2.88.2" in
let default_hashes = {
  "2.88.2" = "cf3f215a640c8a4257f14317586b8f1fdd25a10a93cb4bdda147c0f9ad88e74f",
}
in

let branch = fun version =>
  let matched = std.string.find "^([0-9]+[.][0-9]+)[.]" version in
  if matched.index == 0 && std.array.length matched.groups == 1 then
    std.array.at 0 matched.groups
  else
    std.fail_with "glib.ncl: version must be MAJOR.MINOR.PATCH"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "glib-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/glib/%{branch version}/glib-%{version}.tar.xz",
        },
      }
  in

  let base_build = [
    pkgs.pcre2,
    pkgs.libffi,
    pkgs.zlib,
    pkgs.gettext,
  ]
  in
  let base_runtime = [
    pkgs.glibc_libs,
    pkgs.gcc_libs,
    pkgs.pcre2,
    pkgs.libffi,
    pkgs.zlib,
  ]
  in
  let base_setup = [
    "--buildtype=release",
    "--libdir=/usr/lib",
    "-Dtests=false",
    "-Dman-pages=disabled",
    "-Dselinux=disabled",
    "-Dlibmount=disabled",
    "-Dsysprof=disabled",
    "-Ddtrace=disabled",
  ]
  in

  # suffix: node-name suffix; introspection: "disabled"/"enabled";
  # extra_build: extra build deps (gobject-introspection for the gir pass).
  let mk_glib = fun suffix =>
    fun introspection =>
      fun extra_build =>
        {
          version | default = default_version,
          hashes | default = default_hashes,
          name = "glib%{suffix}-%{version}",
          tag = "Meson",
          deps = {
            build = base_build @ extra_build,
            runtime = base_runtime,
          },
          config = {
            setup_args = base_setup @ ["-Dintrospection=%{introspection}"],
          },
          inputs = {
            source = mk_src version (hashes."%{version}"),
          },
        }
  in

  let glib_gen1 = mk_glib "-gen1" "disabled" [] in
  let glib = mk_glib "" "enabled" [pkgs.gobject_introspection] in

  {
    include [
      glib_gen1,
      glib,
    ],
  }
