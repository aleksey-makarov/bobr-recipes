fun pkgs =>
  let glu_src = {
    version | default = "9.0.3",
    name = "glu-src-%{version}",
    tag = "Source",
    object_hash | default = "bd43fe12f374b1192eb15fe20e45ff456b9bc26ab57f0eee919f96ca0f8a330f",
    origin = {
      tag = "Http",
      url = [
        "https://archive.mesa3d.org/glu/glu-%{version}.tar.xz",
        "https://sources.buildroot.net/libglu/glu-%{version}.tar.xz",
      ],
    },
  }
  in

  let glu = {
    name = "glu-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libglvnd,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
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
      source = pkgs.glu_src,
    },
  }
  in

  {
    include [
      glu_src,
      glu,
    ],
  }
