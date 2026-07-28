fun pkgs =>
  let libglvnd_src = fun version => fun hash => {
    name = "libglvnd-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url =
        "https://github.com/NVIDIA/libglvnd/archive/refs/tags/v%{version}.tar.gz",
    },
  }
  in

  # Vendor-neutral EGL/OpenGL dispatch for the host graphics stack. X11 and
  # GLX are deliberately disabled: HostBundle graphics is Wayland-only.
  let libglvnd = {
    version | default = "1.7.0",
    source_object_hash
      | default
      = "073e7292788d4d3eeb45ea6c7bdcce9bfdb3b3eef8d7dbd47f2f30dce046ef98",
    name = "libglvnd-%{version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dx11=disabled",
        "-Dglx=disabled",
        "-Degl=true",
        "-Dhgl=false",
        "-Dgles1=false",
        "-Dgles2=true",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -s /usr/lib/libOpenGL.so.0
            test -s /usr/lib/libEGL.so.1
            test -s /usr/lib/libGLESv2.so.2
            test -s /usr/lib/libGLdispatch.so.0
            test ! -e /usr/lib/libGL.so
            test ! -e /usr/lib/libGLX.so
          "%,
        ],
      },
    },
    inputs = {
      source = libglvnd_src version source_object_hash,
    },
  }
  in

  {
    include [
      libglvnd,
    ],
  }
