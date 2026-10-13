# kmscube has no releases, so its Source version is the pinned Git commit.
# The guest and host variants intentionally share the same source but link
# against different Mesa stacks.
fun pkgs =>
  let kmscube_src = {
    version | default = "f60e50e887d3c49e91ac9b06d8199b36152632fa",
    name = "kmscube-src-%{version}",
    tag = "Source",
    object_hash | default = "e676b733d351d345b9cbf919dfaf84a5ef16e71f328c542f5614027bd4ca2e05",
    origin = {
      tag = "Http",
      url = "https://gitlab.freedesktop.org/mesa/kmscube/-/archive/%{version}/kmscube-%{version}.tar.gz",
    },
  }
  in

  # Minimal DRM/KMS + GBM + EGL/GLES smoke test: `kmscube -D /dev/dri/card0`
  # does an atomic modeset and renders a spinning cube straight to the virtio
  # scanout -- no Wayland/X compositor. First real userspace-graphics check.
  let kmscube_guest = {
    name = "kmscube-guest-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libdrm,
        pkgs.mesa_guest,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libdrm_libs,
        pkgs.mesa_guest,
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
      source = pkgs.kmscube_src,
    },
  }
  in

  let kmscube = {
    name = "kmscube-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libdrm,
        pkgs.mesa,
        pkgs.libglvnd,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libdrm_libs,
        pkgs.mesa,
        pkgs.libglvnd,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "-Dgstreamer=disabled",
      ],
    },
    inputs = {
      source = pkgs.kmscube_src,
    },
  }
  in

  {
    include [
      kmscube_guest,
      kmscube,
      kmscube_src,
    ],
  }
