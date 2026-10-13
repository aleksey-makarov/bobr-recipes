let recipe = import "../recipe-lib.ncl" in
# GLib / GObject / GIO -- the base of the GNOME stack. Built in two passes to
# break the glib <-> gobject-introspection cycle:
#   glib_gen1 (introspection off) -> gobject-introspection -> glib (gir on).
# Downstream uses `glib` (has the GLib/GObject/Gio typelibs).
let br = import "../build-rootfs.ncl" in

let branch = recipe.version_prefix 2 in

fun pkgs =>
  let glib_src = {
    version | default = "2.88.2",
    name = "glib-src-%{version}",
    tag = "Source",
    object_hash | default = "cf3f215a640c8a4257f14317586b8f1fdd25a10a93cb4bdda147c0f9ad88e74f",
    origin = {
      tag = "Http",
      url = "https://download.gnome.org/sources/glib/%{branch version}/glib-%{version}.tar.xz",
    },
  }
  in

  # glib's own link deps (used both as build deps and in the build rootfs).
  let base_build = [
    pkgs.pcre2,
    pkgs.libffi,
    pkgs.zlib,
    pkgs.gettext,
  ]
  in
  let base_runtime = [
    pkgs.c_runtime,
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
    name = "glib-gen1-%{inputs.source.version}",
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
          # gen1 is a self-contained private-prefix tool package: both its
          # executables and shared libraries must find sibling GLib libraries
          # without relying on an ambient LD_LIBRARY_PATH.
          "-Dc_link_args=-Wl,-rpath,%{gen1_prefix}/lib",
        ],
    },
    inputs = {
      source = pkgs.glib_src,
    },
  }
  in

  # The final gir pass, as a MesonRootfs recipe: it supplies its own build rootfs
  # (_rootfs) instead of letting the builder derive it. That rootfs is the normal
  # meson build deps plus glib's own build deps, but with the not-yet-built final
  # glib substituted by glib_gen1 -- so the recipe builds against gen1 and there
  # is no glib-in-its-own-build-rootfs cycle. deps.build is ignored for *Rootfs
  # recipes; deps.runtime is honest (the final glib's runtime), so a runtime
  # closure ships this glib and never gen1. PKG_CONFIG_PATH selects gen1's build
  # metadata; its installed ELF files carry their own RUNPATH.
  let glib = {
    name = "glib-%{inputs.source.version}",
    tag = "MesonRootfs",
    deps = {
      build = [],
      runtime = base_runtime,
    },
    config = {
      setup_args = base_setup @ ["-Dintrospection=enabled"],
      env = {
        PKG_CONFIG_PATH = "%{gen1_prefix}/lib/pkgconfig",
      },
    },
    inputs = {
      source = pkgs.glib_src,
      _rootfs =
        br.build_rootfs_closure_substituting
          pkgs
          "glib-%{inputs.source.version}-build-rootfs"
          (br.meson_build_deps pkgs @ base_build @ [pkgs.gobject_introspection, pkgs.glib_gen1])
          pkgs.glib
          pkgs.glib_gen1,
    },
  }
  in

  {
    include [
      glib_src,
      glib_gen1,
      glib,
    ],
  }
