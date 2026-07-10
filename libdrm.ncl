let recipe = import "recipe-lib.ncl" in
let version = "2.4.134" in

fun pkgs =>
  let libdrm_src = {
    name = "libdrm-src-%{version}",
    tag = "Source",
    object_hash = "ac5e74d157830eb8bee44c6a6bf3ad49774ef0dd2a72bdad74a8f20308b52a95",
    origin = {
      tag = "Http",
      url = "https://dri.freedesktop.org/libdrm/libdrm-%{version}.tar.xz",
    },
  }
  in

  let libdrm = {
    name = "libdrm-%{version}",
    tag = "Meson",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
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
      source = libdrm_src,
    },
  }
  in

  let libdrm_libs =
    recipe.split.libs libdrm [
      "usr/lib/libdrm.so*",
      "usr/lib/libdrm_*.so*",
    ]
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
        ],
      },
    }
  in

  {
    include [
      libdrm,
      libdrm_libs,
    ],
  }
