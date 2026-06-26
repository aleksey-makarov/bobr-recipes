let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kmod_src = {
    name = "kmod-src-34.2",
    tag = "Source",
    object_hash = "fed8dc21c764926311375101d5d1c008c3cad651302f8d7d93470c33c3ddf9ae",
    origin = {
      tag = "Http",
      url = "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz",
    },
  }
  in

  let kmod = {
    name = "kmod-34.2",
    tag = "Meson",
    deps = {
      build = [
        pkgs.openssl,
        pkgs.zstd,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.openssl_libs,
        pkgs.zstd,
      ],
    },
    config = {
      pre_configure = {
        name = "patch_requires_private",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i '/requires_private : libkmod_deps,/d' meson.build",
        ],
      },
      setup_args = [
        "--buildtype=release",
        "--sbindir=/usr/bin",
        "-Dmanpages=false",
      ],
    },
    inputs = {
      source = kmod_src,
    },
  }
  in

  {
    include [
      kmod,
    ],
  }
