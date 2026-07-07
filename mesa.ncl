let version = "26.1.4" in

fun pkgs =>
  let mesa_src = {
    name = "mesa-src-%{version}",
    tag = "Source",
    object_hash = "9fa968e496e18034f28ffeb6dee951bc1e0ded8ecac16a5fbcfdf9dc725ddfa1",
    origin = {
      tag = "Http",
      url = "https://archive.mesa3d.org/mesa-%{version}.tar.xz",
    },
  }
  in

  # Graphics stack for a QEMU virtio-gpu guest. GL/GLES goes through the virgl
  # Gallium driver, whose scanout presents to the qemu window; the venus/blob
  # scanout does not display on the current qemu 10.1 / virglrenderer 1.2 (the
  # guest renders and issues set_scanout_blob + flush without error, but nothing
  # appears -- only classic transfer-based scanouts show). The venus Vulkan
  # driver (`virtio`) forwards Vulkan to the host for Vulkan apps; zink
  # (GL-on-Vulkan) is built too but is not the default for virtio-gpu. No LLVM,
  # The Wayland platform (-Dplatforms=wayland) makes Mesa's WSI advertise
  # VK_KHR_wayland_surface (venus) and provide the Wayland EGL platform, so
  # Wayland GL/Vulkan clients (incl. the GNOME session) can create surfaces.
  # Zink/venus need the Vulkan headers at build and the loader at runtime.
  let mesa = {
    name = "mesa-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libdrm,
        pkgs.zlib,
        pkgs.zstd,
        pkgs.expat,
        pkgs.bison,
        pkgs.flex,
        pkgs.vulkan_headers,
        pkgs.wayland,
        pkgs.wayland_protocols,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libdrm_libs,
        pkgs.zlib,
        pkgs.zstd,
        pkgs.expat,
        pkgs.vulkan_loader,
        pkgs.wayland,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dplatforms=wayland",
        "-Dgallium-drivers=virgl,zink",
        "-Dvulkan-drivers=virtio",
        "-Dllvm=disabled",
        "-Dgbm=enabled",
        "-Degl=enabled",
        "-Dgles2=enabled",
        "-Dopengl=true",
        "-Dglx=disabled",
        "-Dglvnd=disabled",
        "-Dshared-glapi=enabled",
        "-Dvideo-codecs=",
      ],
    },
    inputs = {
      source = mesa_src,
    },
  }
  in

  {
    include [
      mesa,
    ],
  }
