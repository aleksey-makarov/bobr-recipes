
fun pkgs =>
  let vulkan_headers_src = fun version => fun hash => {
    name = "vulkan-headers-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/vulkan-sdk-%{version}.tar.gz",
    },
  }
  in

  # Header-only (+ registry + CMake package config), consumed by vulkan-loader,
  # Mesa's venus/zink, and vulkan-tools. Built with the Cmake builder, which
  # bakes in -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release and installs
  # into the overlay root; no extra flags needed.
  let vulkan_headers = {
    version | default = "1.4.350.0",
    source_object_hash | default = "70270d10bf2c1e074a06ee37a50b75d332993d1b80a1d9526eeed2da6d82ed22",
    name = "vulkan-headers-%{version}",
    tag = "Cmake",
    deps = {
      build = [],
      runtime = [],
    },
    config = {},
    inputs = {
      source = vulkan_headers_src version source_object_hash,
    },
  }
  in

  {
    include [
      vulkan_headers,
    ],
  }
