fun pkgs =>
  let glslang_src = fun sdk_version => fun hash => {
    name = "glslang-src-%{sdk_version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/glslang/archive/refs/tags/vulkan-sdk-%{sdk_version}.tar.gz",
    },
  }
  in

  # Build the compiler against the matching installed SPIRV-Tools release,
  # instead of populating glslang's in-tree External directory.
  let glslang = {
    sdk_version | default = "1.4.350.0",
    source_object_hash
      | default
      = "a6885b1631fd77c89cd689b939cf2b3032c5ec13ee99250270d34bcad1efc10c",
    name = "glslang-%{sdk_version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.spirv_tools,
        pkgs.python,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
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
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            /usr/bin/glslangValidator --version
            test -s /usr/lib64/libglslang.a
          "%,
        ],
      },
    },
    inputs = {
      source = glslang_src sdk_version source_object_hash,
    },
  }
  in

  {
    include [
      glslang,
    ],
  }
