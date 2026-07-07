let version = "1.4.350.0" in

fun pkgs =>
  let vulkan_loader_src = {
    name = "vulkan-loader-src-%{version}",
    tag = "Source",
    object_hash = "7d4e10fdf76953653951701f9bfa6cccdc59763625d47b3997ad55bf2773ae50",
    origin = {
      tag = "Http",
      url = "https://github.com/KhronosGroup/Vulkan-Loader/archive/refs/tags/vulkan-sdk-%{version}.tar.gz",
    },
  }
  in

  # The Vulkan loader (libvulkan.so.1): dispatches to ICDs listed in
  # /usr/share/vulkan/icd.d (venus from Mesa). Needed at runtime by Zink and any
  # Vulkan app. X11 WSI is off (no X11); Wayland WSI is just a compile define, no
  # extra deps. find_package(PkgConfig REQUIRED) runs unconditionally -> pkgconf.
  let vulkan_loader = {
    name = "vulkan-loader-%{version}",
    tag = "Makefile",
    deps = {
      build = [
        pkgs.cmake,
        pkgs.vulkan_headers,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      pre_build = {
        name = "cmake_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "cmake -S . -B . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUPDATE_DEPS=OFF -DBUILD_TESTS=OFF -DBUILD_WSI_XCB_SUPPORT=OFF -DBUILD_WSI_XLIB_SUPPORT=OFF -DBUILD_WSI_XLIB_XRANDR_SUPPORT=OFF -DBUILD_WSI_WAYLAND_SUPPORT=ON",
        ],
      },
    },
    inputs = {
      source = vulkan_loader_src,
    },
  }
  in

  {
    include [
      vulkan_loader,
    ],
  }
