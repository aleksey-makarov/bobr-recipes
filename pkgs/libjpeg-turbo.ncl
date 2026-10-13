# libjpeg-turbo -- JPEG codec, needed by gdk-pixbuf. CMake-only (3.x dropped
# autotools), built with the Cmake builder. SIMD is off to avoid a nasm build
# dep.
# Configure version and hash through `pkgs.libjpeg_turbo_src`.
fun pkgs =>
  let libjpeg_turbo_src = {
    version | default = "3.1.0",
    name = "libjpeg-turbo-src-%{version}",
    tag = "Source",
    object_hash | default = "9564c72b1dfd1d6fe6274c5f95a8d989b59854575d4bbee44ade7bc17aa9bc93",
    origin = {
      tag = "Http",
      url = "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/%{version}/libjpeg-turbo-%{version}.tar.gz",
    },
  }
  in

  let libjpeg_turbo = {
    name = "libjpeg-turbo-%{inputs.source.version}",
    tag = "Cmake",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      cmake_args = [
        "-DCMAKE_INSTALL_LIBDIR=lib",
        "-DCMAKE_SKIP_INSTALL_RPATH=ON",
        "-DENABLE_STATIC=0",
        "-DWITH_SIMD=0",
      ],
    },
    inputs = {
      source = pkgs.libjpeg_turbo_src,
    },
  }
  in

  {
    include [
      libjpeg_turbo_src,
      libjpeg_turbo,
    ],
  }
