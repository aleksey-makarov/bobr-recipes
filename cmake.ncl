let version = "3.31.6" in

fun pkgs =>
  let cmake_src = {
    name = "cmake-src-%{version}",
    tag = "Source",
    object_hash = "fb34d955c7e94fa7f84d82194c613c2da1a99491190335ff3d9602e2b97fb2e8",
    origin = {
      tag = "Http",
      url = "https://github.com/Kitware/CMake/releases/download/v%{version}/cmake-%{version}.tar.gz",
    },
  }
  in

  # Bootstrap build: no cmake exists yet, so ./bootstrap builds a bootstrap
  # cmake and then the full one; the Makefile builder then runs `make` and
  # `make DESTDIR=... install`. Bundled deps (curl/zlib/libarchive/expat/...) are
  # used; OpenSSL is off (not in the build rootfs, and not needed here). Needed
  # to build the CMake-based vulkan-headers/loader/tools.
  let cmake = {
    name = "cmake-%{version}",
    tag = "Makefile",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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
      source = cmake_src,
    },
  }
  in

  {
    include [
      cmake,
    ],
  }
