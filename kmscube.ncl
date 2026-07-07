let commit = "f60e50e887d3c49e91ac9b06d8199b36152632fa" in
# kmscube has no releases; pin a git commit. The version carries the commit
# date so the package attribute resolves to `kmscube`.
let version = "20251024-f60e50e" in

fun pkgs =>
  let kmscube_src = {
    name = "kmscube-src-%{version}",
    tag = "Source",
    object_hash = "4319a1818fd41eea19cb9394f3ce5adf3f5e4eae8d0aa555a6ddc8fbc73bb244",
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
