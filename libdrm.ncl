let recipe = import "recipe-lib.ncl" in
let version = "2.4.134" in

fun pkgs =>
  let libdrm_src = {
    name = "libdrm-src-%{version}",
    tag = "Source",
    object_hash = "c6842c0a28dc5f6512e04b754c2cc9d55a190932145914dd590c29b30f45b688",
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
