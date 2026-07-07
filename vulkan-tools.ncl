let version = "1.4.350.0" in

fun pkgs =>
  let vulkan_tools_src = {
    name = "vulkan-tools-src-%{version}",
    tag = "Source",
    object_hash = "a9cb1857d42741a288e02c73d38da5b540039e0ca160d01fae34ba42e26e01ad",
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
    name = "vulkan-tools-%{version}",
    tag = "Makefile",
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
      source = vulkan_tools_src,
    },
  }
  in

  {
    include [
      vulkan_tools,
    ],
  }
