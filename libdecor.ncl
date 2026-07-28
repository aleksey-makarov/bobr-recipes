fun pkgs =>
  let libdecor_src = fun version => fun hash => {
    name = "libdecor-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url =
        "https://gitlab.freedesktop.org/libdecor/libdecor/-/archive/%{version}/libdecor-%{version}.tar.gz",
    },
  }
  in

  let libdecor = {
    version | default = "0.2.5",
    source_object_hash
      | default
      = "39c109a9a7eae943ba34d18a282c447d5729f9c486c8bc05ea305e4acd341522",
    name = "libdecor-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.cairo,
        pkgs.pango,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.libxkbcommon,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.cairo,
        pkgs.pango,
        pkgs.wayland,
        pkgs.libxkbcommon,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Ddemo=false",
        "-Ddbus=disabled",
        "-Dgtk=disabled",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -s /usr/lib/libdecor-0.so.0
            test -s /usr/lib/pkgconfig/libdecor-0.pc
          "%,
        ],
      },
    },
    inputs = {
      source = libdecor_src version source_object_hash,
    },
  }
  in

  {
    include [
      libdecor,
    ],
  }
