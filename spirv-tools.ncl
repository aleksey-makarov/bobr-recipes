fun pkgs =>
  let spirv_tools_src = fun sdk_version => fun hash => {
    name = "spirv-tools-src-%{sdk_version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/SPIRV-Tools/archive/refs/tags/vulkan-sdk-%{sdk_version}.tar.gz",
    },
  }
  in

  # libclc's SPIR-V backend needs spirv-link, while Mesa also benefits from
  # keeping the complete matching SDK tool set available at build time.
  let spirv_tools = {
    sdk_version | default = "1.4.350.0",
    source_object_hash
      | default
      = "446b288fe76d3f31bbf9a405d62b97020ac0f135edb0ed5dbdf1136c488138f5",
    name = "spirv-tools-%{sdk_version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.spirv_headers,
        pkgs.python,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      cmake_args = [
        "-DSPIRV-Headers_SOURCE_DIR=/usr",
        "-DSPIRV_SKIP_TESTS=ON",
        "-DSPIRV_WERROR=OFF",
        "-DBUILD_SHARED_LIBS=OFF",
      ],
      post_install = {
        name = "check_install",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            /usr/bin/spirv-link --version
            test -s /usr/lib64/libSPIRV-Tools.a
            test -s /usr/lib64/pkgconfig/SPIRV-Tools.pc
          "%,
        ],
      },
    },
    inputs = {
      source = spirv_tools_src sdk_version source_object_hash,
    },
  }
  in

  {
    include [
      spirv_tools,
    ],
  }
