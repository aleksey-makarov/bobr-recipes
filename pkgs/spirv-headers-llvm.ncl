fun pkgs =>
  let spirv_headers_llvm_src = {
    version
      | default
      = "948a3b0997e2dffea5484b3df7bd5590c5b844cc",
    name = "spirv-headers-llvm-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "19eff765f08d0b8ff5f80ba3c2e902a6baf54123bff50ca383db633ee5b6f778",
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/SPIRV-Headers/archive/%{version}.tar.gz",
    },
  }
  in

  # SPIRV-LLVM-Translator pins an exact headers revision independently from
  # the Vulkan SDK. Keep that build-only input separate from the SDK-aligned
  # public spirv_headers package.
  let spirv_headers_llvm = {
    name = "spirv-headers-llvm-%{inputs.source.version}",
    tag = "Cmake",
    deps = {
      build = [],
      runtime = [],
    },
    config = {},
    inputs = {
      source = pkgs.spirv_headers_llvm_src,
    },
  }
  in

  {
    include [
      spirv_headers_llvm_src,
      spirv_headers_llvm,
    ],
  }
