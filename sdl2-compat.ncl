fun pkgs =>
  let sdl2_compat_src = fun version => fun hash => {
    name = "sdl2-compat-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url =
        "https://github.com/libsdl-org/sdl2-compat/archive/refs/tags/release-%{version}.tar.gz",
    },
  }
  in

  let sdl2_compat = {
    version | default = "2.32.68",
    source_object_hash | default = "72f846becfd2d321da3d2e7a15410f5f156d904257f4c4c608b546614113936b",
    name = "sdl2-compat-%{version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.sdl3,
      ],
      # sdl2-compat opens libSDL3 dynamically, so this dependency must be
      # explicit even though it is not visible through DT_NEEDED.
      runtime = [
        pkgs.glibc_libs,
        pkgs.sdl3,
      ],
    },
    config = {
      cmake_args = [
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_INSTALL_LIBDIR=lib",
        "-DSDL2COMPAT_TESTS=OFF",
        "-DSDL2COMPAT_X11=OFF",
      ],
      post_install = {
        name = "install_sdl2_pkgconfig_alias",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -s /usr/lib/libSDL2-2.0.so.0
            test -s /usr/lib/pkgconfig/sdl2-compat.pc
            test ! -e /usr/lib/pkgconfig/sdl2.pc
            ln -s sdl2-compat.pc /usr/lib/pkgconfig/sdl2.pc
          "%,
        ],
      },
    },
    inputs = {
      source = sdl2_compat_src version source_object_hash,
    },
  }
  in

  {
    include [sdl2_compat],
  }
