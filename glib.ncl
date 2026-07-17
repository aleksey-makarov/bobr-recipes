# GLib / GObject / GIO -- the base of the GNOME stack. Built in two passes to
# break the glib <-> gobject-introspection cycle:
#   glib_gen1 (introspection off) -> gobject-introspection -> glib (gir on).
# Downstream uses `glib` (has the GLib/GObject/Gio typelibs). `version`/`source_object_hash`
# are node fields (overridable), as in linux.ncl.

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

  # The gen1 (introspection-off) pass installs into a private prefix instead of
  # /usr so it does not occupy the paths the final glib installs to. Both passes
  # then build additively (SandboxInstall): gen1 adds files under this prefix,
  # the final glib adds its files under /usr, and nothing overwrites anything.
  # gobject-introspection and the final glib are pointed at this prefix (see
  # their env), and libglib there is found at build time via an rpath baked into
  # gobject-introspection.
  let gen1_prefix = "/usr/lib/glib-gen1" in

  # suffix: node-name suffix; introspection: "disabled"/"enabled";
  # extra_build: extra build deps (gobject-introspection for the gir pass);
  # extra_setup: extra meson setup args (gen1 overrides prefix/libdir);
  # extra_env: extra build env (the gir pass points the scanner at gen1).
  let mk_glib = fun suffix =>
    fun introspection =>
      fun extra_build =>
        fun extra_setup =>
          fun extra_env =>
            {
              version | default = "2.88.2",
              source_object_hash | default = "cf3f215a640c8a4257f14317586b8f1fdd25a10a93cb4bdda147c0f9ad88e74f",
              name = "glib%{suffix}-%{version}",
              tag = "MesonInstall",
              deps = {
                build = base_build @ extra_build,
                runtime = base_runtime,
              },
              config =
                { setup_args = base_setup @ ["-Dintrospection=%{introspection}"] @ extra_setup }
                & (if extra_env == {} then {} else { env = extra_env }),
              inputs = {
                source = mk_src version source_object_hash,
              },
            }
  in

  let glib_gen1 =
    mk_glib "-gen1" "disabled" [] [
      "--prefix=%{gen1_prefix}",
      "--libdir=%{gen1_prefix}/lib",
    ] {}
  in
  # The gir pass runs g-ir-scanner (from gobject-introspection), whose C
  # extension loads gen1's libglib/libgirepository from the private prefix;
  # point the loader there for the duration of the build.
  let glib =
    mk_glib "" "enabled" [pkgs.gobject_introspection, pkgs.glib_gen1] [] {
      PKG_CONFIG_PATH = "%{gen1_prefix}/lib/pkgconfig",
      LD_LIBRARY_PATH = "%{gen1_prefix}/lib",
    }
  in

  {
    include [
      glib_gen1,
      glib,
    ],
  }
