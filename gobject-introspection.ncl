# gobject-introspection -- the GIR scanner/compiler and libgirepository, needed
# to build typelibs (gjs and most GNOME libs consume them). Built against
# glib_gen1 (no-gir glib) to break the glib<->g-i cycle; its runtime dep is also
# glib_gen1 (NOT the final glib) so that glib's gir pass, which build-deps on
# g-i, does not form a build-graph cycle. In the rootfs the final glib provides
# the identically-versioned libglib. `version`/`source_object_hash` are node fields
# (overridable), as in linux.ncl.

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
    tag = "MesonInstall",
    deps = {
      build = [
        pkgs.glib_gen1,
        pkgs.flex,
        pkgs.bison,
        pkgs.libffi,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.glib_gen1,
        pkgs.libffi,
      ],
    },
    config = {
      # glib_gen1 installs into a private prefix (/usr/lib/glib-gen1), not /usr,
      # so g-i is pointed there: pkg-config finds glib's .pc files, and the rpath
      # lets libgirepository/g-ir-scanner load gen1's libglib at build time. The
      # rpath is harmless in the final image (that directory does not exist there,
      # so the loader falls back to /usr/lib, i.e. the final glib).
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
    },
  }
  in

  {
    include [
      gobject_introspection,
    ],
  }
