fun pkgs =>
  let glu_src = fun version => fun hash => {
    name = "glu-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://archive.mesa3d.org/glu/glu-%{version}.tar.xz",
    },
  }
  in

  let glu = {
    version | default = "9.0.3",
    source_object_hash
      | default
      = "bd43fe12f374b1192eb15fe20e45ff456b9bc26ab57f0eee919f96ca0f8a330f",
    name = "glu-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libglvnd,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libglvnd,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -s /usr/lib/libGLU.so.1
            test -s /usr/lib/pkgconfig/glu.pc
          "%,
        ],
      },
    },
    inputs = {
      source = glu_src version source_object_hash,
    },
  }
  in

  {
    include [
      glu,
    ],
  }
