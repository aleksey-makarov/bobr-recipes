# Mesa uses libclc's SPIR-V builtins to compile internal CLC programs for
# Intel and NVK. This is a build-only package: Mesa embeds the generated
# programs in its drivers, so neither libclc nor the LLVM toolchain belongs in
# a runtime closure.
#
# Build libclc through LLVM's standalone runtimes entry point. This consumes
# the matched prebuilt LLVM tools without importing LLVMExports.cmake, whose
# upstream package describes every large standalone LLVM executable.
fun pkgs =>
  let libclc_src = fun version => fun hash => {
    name = "libclc-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-%{version}/llvm-project-%{version}.src.tar.xz",
    },
  }
  in

  let libclc = {
    version | default = "22.1.8",
    source_object_hash
      | default
      = "922f1817a0df7b1489272d18134ee0087a8b068828f87ac63b9861b1a9965888",
    name = "libclc-%{version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.llvm_bin,
        pkgs.python,
        pkgs.spirv_llvm_translator,
      ],
      runtime = [],
    },
    config = {
      source_subdir = "runtimes",
      cmake_args = [
        "-DLLVM_ENABLE_RUNTIMES=libclc",
        "-DLLVM_INCLUDE_TESTS=OFF",
        "-DLLVM_INCLUDE_DOCS=OFF",
        "-DLLVM_PACKAGE_VERSION=%{version}",
        # The first HostBundle target is x86_64, and Mesa embeds this library
        # with -Dstatic-libclc=spirv64. Do not spend build time producing the
        # unused 32-bit-address SPIR-V variant.
        "-DLIBCLC_TARGETS_TO_BUILD=spirv64-mesa3d-",
        # The LLVM 22 native SPIR-V backend currently fails to resolve one of
        # libclc's denormal helpers at the final link. Use the release-matched
        # llvm-spirv translator, which is also what Mesa links as
        # LLVMSPIRVLib.
        "-DLIBCLC_USE_SPIRV_BACKEND=OFF",
        "-DLIBCLC_CUSTOM_LLVM_TOOLS_BINARY_DIR=/usr/bin",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            # The runtimes entry point installs into Clang's resource
            # directory, while libclc.pc intentionally advertises the
            # distribution-style share/clc directory used by Mesa.
            install -d /usr/share/clc
            mv /usr/lib/clang/22/lib/libclc/* /usr/share/clc/
            rmdir /usr/lib/clang/22/lib/libclc

            test -s /usr/share/pkgconfig/libclc.pc
            test -s /usr/share/clc/spirv64-mesa3d-.spv
          "%,
        ],
      },
    },
    inputs = {
      source = libclc_src version source_object_hash,
    },
  }
  in

  {
    include [
      libclc,
    ],
  }
