let commit = "f60e50e887d3c49e91ac9b06d8199b36152632fa" in
# kmscube has no releases; pin a git commit. The version carries the commit
# date so the package attribute resolves to `kmscube`.
let version = "20251024-f60e50e" in

fun pkgs =>
  let kmscube_src = {
    name = "kmscube-src-%{version}",
    tag = "Source",
    object_hash = "e676b733d351d345b9cbf919dfaf84a5ef16e71f328c542f5614027bd4ca2e05",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/mesa/kmscube/-/archive/%{commit}/kmscube-%{commit}.tar.gz",
    },
  }
  in

  # Minimal DRM/KMS + GBM + EGL/GLES smoke test: `kmscube -D /dev/dri/card0`
  # does an atomic modeset and renders a spinning cube straight to the virtio
  # scanout -- no Wayland/X compositor. First real userspace-graphics check.
  let kmscube = {
    name = "kmscube-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libdrm,
        pkgs.mesa,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.libdrm_libs,
        pkgs.mesa,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        # No gstreamer video-cube support; keep it to the bare EGL/GLES cube.
        "-Dgstreamer=disabled",
      ],
    },
    inputs = {
      source = kmscube_src,
    },
  }
  in

  {
    include [
      kmscube,
    ],
  }
