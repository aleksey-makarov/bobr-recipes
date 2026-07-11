# libepoxy -- GL/EGL function-pointer dispatch, used by GTK4. It dlopens the GL
# stack (Mesa) at runtime; X11/GLX off (pure Wayland/EGL). `version`/`source_object_hash`
# are node fields (overridable), as in linux.ncl.

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "libepoxy-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/anholt/libepoxy/archive/refs/tags/%{version}.tar.gz",
        },
      }
  in

  let libepoxy = {
    version | default = "1.5.10",
    source_object_hash | default = "a7ced37f4102b745ac86d6a70a9da399cc139ff168ba6b8002b4d8d43c900c15",
    name = "libepoxy-%{version}",
    tag = "Meson",
    deps = {
      build = [
        pkgs.mesa,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.mesa,
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
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      libepoxy,
    ],
  }
