fun pkgs =>
  let glmark2_src = fun version => fun hash => {
    name = "glmark2-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url =
        "https://github.com/glmark2/glmark2/archive/refs/tags/%{version}.tar.gz",
    },
  }
  in

  let data_path_environment_patch = {
    name = "glmark2-data-path-environment-patch",
    tag = "Source",
    object_hash =
      import "data-path-environment.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "pkgs/glmark2/data-path-environment.patch",
    },
  }
  in

  let glmark2 = {
    version | default = "2023.01",
    source_object_hash
      | default
      = "8fece3fc323b643644a525be163dc4931a4189971eda1de8ad4c1712c5db3d67",
    name = "glmark2-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.mesa,
        pkgs.libglvnd,
        pkgs.libjpeg_turbo,
        pkgs.libpng,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.mesa,
        pkgs.libglvnd,
        pkgs.libjpeg_turbo,
        pkgs.libpng,
        pkgs.wayland,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dflavors=wayland-gl,wayland-glesv2",
        "-Ddata-path=/usr/share/glmark2",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            test -x /usr/bin/glmark2-wayland
            test -x /usr/bin/glmark2-es2-wayland
            test -d /usr/share/glmark2
            test ! -e /usr/bin/glmark2
          "%,
        ],
      },
    },
    inputs = {
      source = glmark2_src version source_object_hash,
      patch_data_path_environment = data_path_environment_patch,
    },
  }
  in

  {
    include [
      data_path_environment_patch,
      glmark2,
    ],
  }
