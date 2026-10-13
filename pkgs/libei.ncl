# libei -- emulated input protocol. Provides both libei-1.0 (client) and
# libeis-1.0 (server); mutter links both, unconditionally. liboeffis (the portal
# helper, sd-bus based) is off -- mutter is the EIS side and does not need it,
# which also drops the sd-bus dependency. The protocol C code is generated at
# build time by proto/ei-scanner, which needs Python jinja2 (pkgs.python_jinja2
# in deps.build -- the interpreter no longer bundles it).
#
# Source is fetched from the freedesktop GitLab archive with `unpack = true`, so
# the object hash is the extracted tree's fsobj-hash rather than the tarball
# bytes -- GitLab regenerates archive tarballs non-reproducibly, but the tree is
# stable.
# Configure version and hash through `pkgs.libei_src`.
fun pkgs =>
  let libei_src = {
    version | default = "1.4.1",
    name = "libei-src-%{version}",
    tag = "Source",
    object_hash | default = "c3e78cdfd27ee4635e657ce7f9c4454fc67ad4dbf0a3f9ada057b130bbafe278",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/libinput/libei/-/archive/%{version}/libei-%{version}.tar.gz",
      unpack = true,
    },
  }
  in

  let libei = {
    name = "libei-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libevdev,
        pkgs.libxkbcommon,
        pkgs.python_jinja2,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libevdev,
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
      source = pkgs.libei_src,
    },
  }
  in

  {
    include [
      libei_src,
      libei,
    ],
  }
