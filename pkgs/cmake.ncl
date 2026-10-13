fun pkgs =>
  let cmake_src = {
    version | default = "3.31.6",
    name = "cmake-src-%{version}",
    tag = "Source",
    object_hash | default = "653427f0f5014750aafff22727fb2aa60c6c732ca91808cfb78ce22ddd9e55f0",
    origin = {
      tag = "Http",
      url = "https://github.com/Kitware/CMake/releases/download/v%{version}/cmake-%{version}.tar.gz",
    },
  }
  in

  # Bootstrap build: no cmake exists yet, so ./bootstrap builds a bootstrap
  # cmake and then the full one; the Makefile builder then runs `make` and
  # `make install` into the overlay root. Bundled deps (curl/zlib/libarchive/expat/...) are
  # used; OpenSSL is off (not in the build rootfs, and not needed here). Needed
  # to build the CMake-based vulkan-headers/loader/tools.
  let cmake = {
    name = "cmake-%{inputs.source.version}",
    tag = "Makefile",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
      ],
    },
    config = {
      pre_build = {
        name = "bootstrap",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "./bootstrap --prefix=/usr --parallel=\"$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)\" -- -DCMAKE_USE_OPENSSL=OFF -DBUILD_TESTING=OFF",
        ],
      },
    },
    inputs = {
      source = pkgs.cmake_src,
    },
  }
  in

  {
    include [
      cmake_src,
      cmake,
    ],
  }
