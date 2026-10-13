# libepoxy -- GL/EGL function-pointer dispatch, used by GTK4. It dlopens the GL
# stack (Mesa) at runtime; X11/GLX off (pure Wayland/EGL).
# Configure version and hash through `pkgs.libepoxy_src`.
fun pkgs =>
  let libepoxy_src = {
    version | default = "1.5.10",
    name = "libepoxy-src-%{version}",
    tag = "Source",
    object_hash | default = "a7ced37f4102b745ac86d6a70a9da399cc139ff168ba6b8002b4d8d43c900c15",
    origin = {
      tag = "Http",
      url = "https://github.com/anholt/libepoxy/archive/refs/tags/%{version}.tar.gz",
    },
  }
  in

  let libepoxy = {
    name = "libepoxy-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.mesa_guest,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.mesa_guest,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dglx=no",
        "-Degl=yes",
        "-Dx11=false",
        "-Dtests=false",
        "-Ddocs=false",
      ],
    },
    inputs = {
      source = pkgs.libepoxy_src,
    },
  }
  in

  # Host graphics variant. The ordinary libepoxy package is built against the
  # virtio-GPU guest Mesa and intentionally keeps that runtime association.
  # Host-side QEMU/virglrenderer instead needs the GLVND ABI backed by the full
  # host Mesa stack, so keep the two dependency closures distinct.
  let libepoxy_host = {
    name = "libepoxy-host-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.libglvnd,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.libglvnd,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        "-Dglx=no",
        "-Degl=yes",
        "-Dx11=false",
        "-Dtests=false",
        "-Ddocs=false",
      ],
    },
    inputs = {
      source = pkgs.libepoxy_src,
    },
  }
  in

  {
    include [
      libepoxy_src,
      libepoxy,
      libepoxy_host,
    ],
  }
