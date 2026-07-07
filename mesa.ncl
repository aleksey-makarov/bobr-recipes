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

  # Accel-only graphics stack for a QEMU virtio-gpu guest: the virgl Gallium
  # driver forwards GL to the host via virglrenderer (qemu -device
  # virtio-vga-gl, gl=on). No LLVM (so no llvmpipe software fallback -- we
  # assume a working host GL), no Vulkan yet (see TODO_vulkan_guest.md), and no
  # window-system platforms (kmscube drives KMS/GBM directly, EGL uses the GBM
  # platform).
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
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libdrm_libs,
        pkgs.zlib,
        pkgs.zstd,
        pkgs.expat,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dplatforms=",
        "-Dgallium-drivers=virgl",
        "-Dvulkan-drivers=",
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
