fun pkgs =>
  let vulkan_loader_src = {
    version | default = "1.4.350.0",
    name = "vulkan-loader-src-%{version}",
    tag = "Source",
    object_hash | default = "91f88fc43abb36821a568c7fbb3f815e9baf946d5fe187928df279708d45e509",
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
    name = "vulkan-loader-%{inputs.source.version}",
    tag = "Cmake",
    deps = {
      build = [
        pkgs.vulkan_headers,
        pkgs.pkgconf,
      ],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      cmake_args = [
        "-DUPDATE_DEPS=OFF",
        "-DBUILD_TESTS=OFF",
        "-DBUILD_WSI_XCB_SUPPORT=OFF",
        "-DBUILD_WSI_XLIB_SUPPORT=OFF",
        "-DBUILD_WSI_XLIB_XRANDR_SUPPORT=OFF",
        "-DBUILD_WSI_WAYLAND_SUPPORT=ON",
      ],
    },
    inputs = {
      source = pkgs.vulkan_loader_src,
    },
  }
  in

  {
    include [
      vulkan_loader_src,
      vulkan_loader,
    ],
  }
