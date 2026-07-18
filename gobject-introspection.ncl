# gobject-introspection -- the GIR scanner/compiler and libgirepository, needed
# to build typelibs (gjs and most GNOME libs consume them). A MesonRootfs recipe:
# it supplies its own build rootfs (_rootfs), built from the normal meson build
# deps plus g-i's own build deps, but with the final glib substituted by
# glib_gen1 (the no-gir glib) -- so g-i builds against gen1 and the
# glib<->gobject-introspection build cycle is broken. deps.build is ignored for
# *Rootfs recipes; deps.runtime is honest (the FINAL glib), so a runtime closure
# ships the final glib and never gen1. `version`/`source_object_hash` are node
# fields (overridable), as in linux.ncl.
let br = import "build-rootfs.ncl" in

let branch = fun version =>
  let matched = std.string.find "^([0-9]+[.][0-9]+)[.]" version in
  if matched.index == 0 && std.array.length matched.groups == 1 then
    std.array.at 0 matched.groups
  else
    std.fail_with "gobject-introspection.ncl: version must be MAJOR.MINOR.PATCH"
in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "gobject-introspection-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://download.gnome.org/sources/gobject-introspection/%{branch version}/gobject-introspection-%{version}.tar.xz",
        },
      }
  in

  let gobject_introspection = {
    version | default = "1.86.0",
    source_object_hash | default = "920d1a3fcedeadc32acff95c2e203b319039dd4b4a08dd1a2dfd283d19c0b9ae",
    name = "gobject-introspection-%{version}",
    tag = "MesonRootfs",
    deps = {
      build = [],
      # Honest runtime dep on the FINAL glib, so a runtime closure ships it, not
      # gen1. (The build environment is _rootfs below, which uses gen1 instead.)
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib,
        pkgs.libffi,
      ],
    },
    config = {
      # gen1 lives in its private prefix (/usr/lib/glib-gen1); point pkg-config
      # and the loader there so g-i builds/links against it. The rpath is
      # harmless in the final image (that dir does not exist there, so the loader
      # falls back to /usr/lib, i.e. the final glib).
      env = {
        PKG_CONFIG_PATH = "/usr/lib/glib-gen1/lib/pkgconfig",
        LD_LIBRARY_PATH = "/usr/lib/glib-gen1/lib",
        LDFLAGS = "-Wl,-rpath,/usr/lib/glib-gen1/lib",
      },
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dcairo=disabled",
        "-Ddoctool=disabled",
        "-Dgtk_doc=false",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
      # Build rootfs: the standard meson build deps + g-i's own build deps, but
      # with the final glib swapped for glib_gen1 so g-i compiles against the
      # no-gir glib (breaking the build cycle).
      _rootfs =
        br.build_rootfs_closure_substituting
          pkgs
          "gobject-introspection-%{version}-build-rootfs"
          (br.meson_build_deps pkgs @ [pkgs.glib, pkgs.flex, pkgs.bison, pkgs.libffi])
          pkgs.glib
          pkgs.glib_gen1,
    },
  }
  in

  {
    include [
      gobject_introspection,
    ],
  }
