fun pkgs =>
  let spirv_headers_llvm_src = fun revision => fun hash => {
    name = "spirv-headers-llvm-src-%{revision}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/SPIRV-Headers/archive/%{revision}.tar.gz",
    },
  }
  in

  # SPIRV-LLVM-Translator pins an exact headers revision independently from
  # the Vulkan SDK. Keep that build-only input separate from the SDK-aligned
  # public spirv_headers package.
  let spirv_headers_llvm = {
    revision
      | default
      = "948a3b0997e2dffea5484b3df7bd5590c5b844cc",
    source_object_hash
      | default
      = "19eff765f08d0b8ff5f80ba3c2e902a6baf54123bff50ca383db633ee5b6f778",
    name = "spirv-headers-llvm-%{revision}",
    tag = "Cmake",
    deps = {
      build = [],
      runtime = [],
    },
    config = {},
    inputs = {
      source =
        spirv_headers_llvm_src revision source_object_hash,
    },
  }
  in

  {
    include [
      spirv_headers_llvm,
    ],
  }
