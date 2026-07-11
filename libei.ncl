# libei -- emulated input protocol. Provides both libei-1.0 (client) and
# libeis-1.0 (server); mutter links both, unconditionally. liboeffis (the portal
# helper, sd-bus based) is off -- mutter is the EIS side and does not need it,
# which also drops the sd-bus dependency. The protocol C code is generated at
# build time by proto/ei-scanner, which needs Python jinja2; that comes with
# `pkgs.python` (a Meson default build dep bundles it), so nothing extra here.
#
# Source is fetched from the freedesktop GitLab archive with `unpack = true`, so
# the object hash is the extracted tree's fsobj-hash rather than the tarball
# bytes -- GitLab regenerates archive tarballs non-reproducibly, but the tree is
# stable. `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libei-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://gitlab.freedesktop.org/libinput/libei/-/archive/%{version}/libei-%{version}.tar.gz",
          unpack = true,
        },
      }
  in

  let libei = {
    version | default = "1.4.1",
    source_object_hash | default = "c3e78cdfd27ee4635e657ce7f9c4454fc67ad4dbf0a3f9ada057b130bbafe278",
    name = "libei-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libevdev,
        pkgs.libxkbcommon,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.libevdev,
        pkgs.libxkbcommon,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dtests=disabled",
        "-Dliboeffis=disabled",
        "-Dlibei=enabled",
        "-Dlibeis=enabled",
      ],
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libei,
    ],
  }
