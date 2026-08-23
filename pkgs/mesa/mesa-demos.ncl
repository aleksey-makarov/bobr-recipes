fun pkgs =>
  let mesa_demos_src = fun version => fun hash => {
    name = "mesa-demos-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://archive.mesa3d.org/demos/mesa-demos-%{version}.tar.xz",
        "https://downloads.yoctoproject.org/mirror/sources/mesa-demos-%{version}.tar.xz",
      ],
    },
  }
  in

  let use_libopengl_patch = {
    name = "mesa-demos-use-libopengl-patch",
    tag = "Source",
    object_hash = import "use-libopengl.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/mesa/use-libopengl.patch",
    },
  }
  in

  # EGL diagnostics and small Wayland rendering demos. Keep every X11/GLX,
  # GLUT, direct-DRM, and Vulkan demo out of this package.
  let mesa_demos = {
    version | default = "9.0.0",
    source_object_hash
      | default
      = "3046a3d26a7b051af7ebdd257a5f23bfeb160cad6ed952329cdff1e9f1ed496b",
    name = "mesa-demos-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.mesa,
        pkgs.libglvnd,
        pkgs.glu,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.libxkbcommon,
        pkgs.libdecor,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.mesa,
        pkgs.libglvnd,
        pkgs.glu,
        pkgs.wayland,
        pkgs.libxkbcommon,
        pkgs.libdecor,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Degl=enabled",
        "-Dgles1=disabled",
        "-Dgles2=enabled",
        "-Dglut=disabled",
        "-Dlibdrm=disabled",
        "-Dosmesa=disabled",
        "-Dvulkan=disabled",
        "-Dwayland=enabled",
        "-Dx11=disabled",
        "-Dwith-system-data-files=true",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -x /usr/bin/eglinfo
            test -x /usr/bin/eglgears_wayland
            test -x /usr/bin/egltri_wayland
            test -x /usr/bin/es2gears_wayland
            test ! -e /usr/bin/glxinfo
            test ! -e /usr/bin/glxgears
          "%,
        ],
      },
    },
    inputs = {
      source = mesa_demos_src version source_object_hash,
      patch_use_libopengl = use_libopengl_patch,
    },
  }
  in

  {
    include [
      use_libopengl_patch,
      mesa_demos,
    ],
  }
