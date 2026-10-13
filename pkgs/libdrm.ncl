let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let libdrm_src = {
    version | default = "2.4.134",
    name = "libdrm-src-%{version}",
    tag = "Source",
    object_hash | default = "ac5e74d157830eb8bee44c6a6bf3ad49774ef0dd2a72bdad74a8f20308b52a95",
    origin = {
      tag = "Http",
      url = [
        "https://dri.freedesktop.org/libdrm/libdrm-%{version}.tar.xz",
        "https://sources.buildroot.net/libdrm/libdrm-%{version}.tar.xz",
      ],
    },
  }
  in

  let libdrm = {
    name = "libdrm-%{inputs.source.version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      setup_args = [
        "--buildtype=release",
        "--libdir=/usr/lib",
        # Only the core libdrm is needed for a virtio-gpu guest (Mesa's virgl
        # driver). Skip man pages / valgrind hooks; vendor GPU helpers are left
        # at their auto default (they build without extra deps and are cheap).
        "-Dman-pages=disabled",
        "-Dvalgrind=disabled",
        "-Dtests=false",
      ],
    },
    inputs = {
      source = pkgs.libdrm_src,
    },
  }
  in

  let libdrm_libs =
    recipe.split.libs
      pkgs.libdrm
      [
        "usr/lib/libdrm.so*",
        "usr/lib/libdrm_*.so*",
      ]
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.c_runtime,
        ],
      },
    }
  in

  {
    include [
      libdrm_src,
      libdrm,
      libdrm_libs,
    ],
  }
