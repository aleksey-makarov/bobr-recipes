fun pkgs =>
  let spirv_headers_src = fun sdk_version => fun hash => {
    name = "spirv-headers-src-%{sdk_version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/SPIRV-Headers/archive/refs/tags/vulkan-sdk-%{sdk_version}.tar.gz",
    },
  }
  in

  # Keep the SPIR-V headers on the same Vulkan SDK release line as the
  # loader, tools, and SPIRV-Tools. Apart from the headers this also installs
  # the registry files and the upstream CMake package metadata.
  let spirv_headers = {
    sdk_version | default = "1.4.350.0",
    source_object_hash
      | default
      = "9905d9341f20388adb852c77dd982f2c4d539fd68e6c1f1bcebf034715f2d1d5",
    name = "spirv-headers-%{sdk_version}",
    tag = "Cmake",
    deps = {
      build = [],
      runtime = [],
    },
    config = {},
    inputs = {
      source = spirv_headers_src sdk_version source_object_hash,
    },
  }
  in

  {
    include [
      spirv_headers,
    ],
  }
