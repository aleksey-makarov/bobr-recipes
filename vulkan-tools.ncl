
fun pkgs =>
  let vulkan_tools_src = fun version => fun hash => {
    name = "vulkan-tools-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/Vulkan-Tools/archive/refs/tags/vulkan-sdk-%{version}.tar.gz",
    },
  }
  in

  # vulkaninfo (ICD/driver smoke) and vkcube (Vulkan render test) for validating
  # the venus path. cube uses the Wayland WSI (runs under Weston); X11 WSI off.
  # Shaders ship as prebuilt SPIR-V, so no glslang. Mock ICD off.
  let vulkan_tools = {
    version | default = "1.4.350.0",
    source_object_hash | default = "3079796d51b29ce49dc7b7c7e243df93b343d54c3be9d4a8292c3231b9698deb",
    name = "vulkan-tools-%{version}",
    tag = "MakefileInstall",
    deps = {
      build = [
        pkgs.cmake,
        pkgs.vulkan_headers,
        pkgs.vulkan_loader,
        pkgs.wayland,
        pkgs.wayland_protocols,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.vulkan_loader,
        pkgs.wayland,
      ],
    },
    config = {
      pre_build = {
        name = "cmake_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "cmake -S . -B . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_ICD=OFF -DBUILD_TESTS=OFF -DBUILD_WSI_XCB_SUPPORT=OFF -DBUILD_WSI_XLIB_SUPPORT=OFF -DBUILD_WSI_WAYLAND_SUPPORT=ON",
        ],
      },
    },
    inputs = {
      source = vulkan_tools_src version source_object_hash,
    },
  }
  in

  {
    include [
      vulkan_tools,
    ],
  }
