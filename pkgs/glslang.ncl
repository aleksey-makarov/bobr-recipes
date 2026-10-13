fun pkgs =>
  let glslang_src = {
    version | default = "1.4.350.0",
    name = "glslang-src-%{version}",
    tag = "Source",
    object_hash
      | default
      = "a6885b1631fd77c89cd689b939cf2b3032c5ec13ee99250270d34bcad1efc10c",
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/glslang/archive/refs/tags/vulkan-sdk-%{version}.tar.gz",
    },
  }
  in

  # Build the compiler against the matching installed SPIRV-Tools release,
  # instead of populating glslang's in-tree External directory.
  let glslang = {
    name = "glslang-%{inputs.source.version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.spirv_tools,
        pkgs.python,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.gcc_libstdcxx,
      ],
    },
    config = {
      cmake_args = [
        "-DBUILD_EXTERNAL=OFF",
        "-DALLOW_EXTERNAL_SPIRV_TOOLS=ON",
        "-DGLSLANG_TESTS=OFF",
        "-DENABLE_GLSLANG_BINARIES=ON",
        "-DENABLE_SPIRV=ON",
        "-DENABLE_OPT=ON",
        "-DENABLE_HLSL=OFF",
        "-DBUILD_SHARED_LIBS=OFF",
        "-DCMAKE_INSTALL_LIBDIR=lib",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            /usr/bin/glslangValidator --version
            test -s /usr/lib/libglslang.a
          "%,
        ],
      },
    },
    inputs = {
      source = pkgs.glslang_src,
    },
  }
  in

  {
    include [
      glslang_src,
      glslang,
    ],
  }
