fun pkgs =>
  let spirv_llvm_translator_src = {
    version | default = "22.1.4",
    name = "spirv-llvm-translator-src-%{version}",
    tag = "Source",
    object_hash | default = "77888f4e22e312d1ac05737407c45dffcc6d0c9c725f9d08bbeb04a6dbe1a5f2",
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/SPIRV-LLVM-Translator/archive/refs/tags/v%{version}.tar.gz",
    },
  }
  in

  # Mesa's CLC compiler links LLVMSPIRVLib. Translator release lines are tied
  # to an LLVM major/minor, so keep this on 22.1 alongside llvm_bin 22.1.8.
  let spirv_llvm_translator = {
    name = "spirv-llvm-translator-%{inputs.source.version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.llvm_bin,
        pkgs.spirv_headers_llvm,
        pkgs.spirv_tools,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
        pkgs.zlib,
      ],
    },
    config = {
      cmake_args = [
        "-DCMAKE_INSTALL_LIBDIR=lib",
        "-DLLVM_DIR=/usr/lib/cmake/llvm",
        "-DLLVM_EXTERNAL_SPIRV_HEADERS_SOURCE_DIR=/usr",
        "-DLLVM_SPIRV_INCLUDE_TESTS=OFF",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            /usr/bin/llvm-spirv --version
            test -s /usr/lib/libLLVMSPIRVLib.a
            test -s /usr/lib/pkgconfig/LLVMSPIRVLib.pc
          "%,
        ],
      },
    },
    inputs = {
      source = pkgs.spirv_llvm_translator_src,
    },
  }
  in

  {
    include [
      spirv_llvm_translator_src,
      spirv_llvm_translator,
    ],
  }
