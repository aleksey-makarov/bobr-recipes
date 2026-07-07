let version = "1.4.350.0" in

fun pkgs =>
  let vulkan_headers_src = {
    name = "vulkan-headers-src-%{version}",
    tag = "Source",
    object_hash = "f0639a85befa55775b9f5c755a866a52ac0f8162b80edabde4de80a834237375",
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/vulkan-sdk-%{version}.tar.gz",
    },
  }
  in

  # Header-only (+ registry + CMake package config), consumed by vulkan-loader,
  # Mesa's venus/zink, and vulkan-tools. Built via the Makefile builder: a
  # pre_build step runs cmake (Unix Makefiles generator), then `make` /
  # `make DESTDIR=... install`.
  let vulkan_headers = {
    name = "vulkan-headers-%{version}",
    tag = "Makefile",
    deps = {
      build = [
        pkgs.cmake,
      ],
      runtime = [],
    },
    config = {
      pre_build = {
        name = "cmake_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "cmake -S . -B . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release",
        ],
      },
    },
    inputs = {
      source = vulkan_headers_src,
    },
  }
  in

  {
    include [
      vulkan_headers,
    ],
  }
