fun pkgs =>
  let sdl3_src = {
    version | default = "3.4.10",
    name = "sdl3-src-%{version}",
    tag = "Source",
    object_hash | default = "0dc11d980ba17250200718fa4e28011da293f27ed92f92203afffe396811f307",
    origin = {
      tag = "Http",
      url = "https://github.com/libsdl-org/SDL/archive/refs/tags/release-%{version}.tar.gz",
    },
  }
  in

  # Host-side SDL: Wayland-only video with desktop OpenGL. Audio and the other
  # host-integration backends are deliberately absent from the QEMU bundle.
  let sdl3 = {
    name = "sdl3-%{inputs.source.version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.pkgconf,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.libxkbcommon,
        pkgs.libdecor,
        pkgs.libglvnd,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.wayland,
        pkgs.libxkbcommon,
        pkgs.libdecor,
        pkgs.libglvnd,
      ],
    },
    config = {
      cmake_args = [
        "-DCMAKE_BUILD_TYPE=Release",
        "-DCMAKE_INSTALL_LIBDIR=lib",
        "-DSDL_SHARED=ON",
        "-DSDL_STATIC=OFF",
        "-DSDL_TEST_LIBRARY=OFF",
        "-DSDL_TESTS=OFF",
        "-DSDL_INSTALL_TESTS=OFF",
        "-DSDL_AUDIO=OFF",
        "-DSDL_DBUS=OFF",
        "-DSDL_IBUS=OFF",
        "-DSDL_KMSDRM=OFF",
        "-DSDL_LIBUDEV=OFF",
        "-DSDL_HIDAPI_LIBUSB=OFF",
        "-DSDL_OPENGL=ON",
        "-DSDL_OPENGLES=ON",
        "-DSDL_VULKAN=OFF",
        "-DSDL_WAYLAND=ON",
        "-DSDL_WAYLAND_SHARED=OFF",
        "-DSDL_WAYLAND_LIBDECOR=ON",
        "-DSDL_WAYLAND_LIBDECOR_SHARED=OFF",
        "-DSDL_X11=OFF",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -s /usr/lib/libSDL3.so.0
            test -s /usr/lib/pkgconfig/sdl3.pc
          "%,
        ],
      },
    },
    inputs = {
      source = pkgs.sdl3_src,
    },
  }
  in

  {
    include [
      sdl3_src,
      sdl3
    ],
  }
