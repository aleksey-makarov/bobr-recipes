# GLib / GObject / GIO -- the base of the GNOME stack. Built in two passes to
# break the glib <-> gobject-introspection cycle:
#   glib_gen1 (introspection off) -> gobject-introspection -> glib (gir on).
# Downstream uses `glib` (has the GLib/GObject/Gio typelibs). `version`/`source_object_hash`
# are node fields (overridable), as in linux.ncl.
let br = import "build-rootfs.ncl" in

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

  let default_version = "2.88.2" in
  let default_hash = "cf3f215a640c8a4257f14317586b8f1fdd25a10a93cb4bdda147c0f9ad88e74f" in

  # glib's own link deps (used both as build deps and in the build rootfs).
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

  # gen1 installs into a private prefix (not /usr) so the final glib's additive
  # install to /usr does not collide with gen1's files in the build rootfs, where
  # both are present. gen1 never reaches the image: the final glib and
  # gobject-introspection declare honest deps on the final glib, so a runtime
  # closure resolves to it, never to gen1.
  let gen1_prefix = "/usr/lib/glib-gen1" in

  # gen1: the no-gir bootstrap pass. A normal Meson package, installed into the
  # private prefix.
  let glib_gen1 = {
    version | default = default_version,
    source_object_hash | default = default_hash,
    name = "glib-gen1-%{version}",
    tag = "Meson",
    deps = {
      build = base_build,
      runtime = base_runtime,
    },
    config = {
      setup_args =
        base_setup
        @ [
          "-Dintrospection=disabled",
          "--prefix=%{gen1_prefix}",
          "--libdir=%{gen1_prefix}/lib",
        ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  # The final gir pass, as a MesonRootfs recipe: it supplies its own build rootfs
  # (_rootfs) instead of letting the builder derive it. That rootfs is the normal
  # meson build deps plus glib's own build deps, but with the not-yet-built final
  # glib substituted by glib_gen1 -- so the recipe builds against gen1 and there
  # is no glib-in-its-own-build-rootfs cycle. deps.build is ignored for *Rootfs
  # recipes; deps.runtime is honest (the final glib's runtime), so a runtime
  # closure ships this glib and never gen1. env points the gir scanner at gen1 in
  # its private prefix.
  let glib = {
    version | default = default_version,
    source_object_hash | default = default_hash,
    name = "glib-%{version}",
    tag = "MesonRootfs",
    deps = {
      build = [],
      runtime = base_runtime,
    },
    config = {
      setup_args = base_setup @ ["-Dintrospection=enabled"],
      env = {
        PKG_CONFIG_PATH = "%{gen1_prefix}/lib/pkgconfig",
        LD_LIBRARY_PATH = "%{gen1_prefix}/lib",
      },
    },
    inputs = {
      source = mk_src version source_object_hash,
      _rootfs =
        br.build_rootfs_closure_substituting
          pkgs
          "glib-%{version}-build-rootfs"
          (br.meson_build_deps pkgs @ base_build @ [pkgs.gobject_introspection, pkgs.glib_gen1])
          pkgs.glib
          pkgs.glib_gen1,
    },
  }
  in

  {
    include [
      glib_gen1,
      glib,
    ],
  }
