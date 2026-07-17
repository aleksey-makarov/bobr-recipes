# libjpeg-turbo -- JPEG codec, needed by gdk-pixbuf. CMake-only (3.x dropped
# autotools), so built via the Makefile builder with a cmake `pre_build` step
# (same pattern as vulkan-loader). SIMD is off to avoid a nasm build dep.
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libjpeg-turbo-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/%{version}/libjpeg-turbo-%{version}.tar.gz",
        },
      }
  in

  let libjpeg_turbo = {
    version | default = "3.1.0",
    source_object_hash | default = "9564c72b1dfd1d6fe6274c5f95a8d989b59854575d4bbee44ade7bc17aa9bc93",
    name = "libjpeg-turbo-%{version}",
    tag = "Makefile",
    deps = {
      build = [
        pkgs.cmake,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      pre_build = {
        name = "cmake_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "cmake -S . -B . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_BUILD_TYPE=Release -DENABLE_STATIC=0 -DWITH_SIMD=0",
        ],
      },
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libjpeg_turbo,
    ],
  }
