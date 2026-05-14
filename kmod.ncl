let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kmod_src = {
    name = "kmod-src-34.2",
    tag = "Source",
    object_hash = "fed8dc21c764926311375101d5d1c008c3cad651302f8d7d93470c33c3ddf9ae",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz",
    },
    meta = {},
  }
  in

  let kmod_build_rootfs = {
    name = "kmod-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs }
      & recipe.numbered_inputs [
        pkgs.openssl,
        pkgs.zstd,
      ],
  }
  in

  let kmod = {
    name = "kmod-34.2",
    tag = "MesonSandbox",
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
        "-Dmanpages=false",
      ],
    },
    inputs = {
      rootfs = kmod_build_rootfs,
      source = kmod_src,
    },
  }
  in

  {
    include [
      kmod_src,
      kmod,
    ],
  }
