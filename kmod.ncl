let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kmod_src = {
    name = "kmod-src-34.2",
    tag = "Fetch",
    config = {
      url = "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz",
      hash = "md5:36f2cc483745e81ede3406fa55e1065a",
    },
    inputs = {},
  }
  in

  let kmod_build_image = {
    name = "kmod-build-image",
    tag = "Image",
    config = { ref_name | default = "kmod-build-image" } & {},
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.openssl,
        pkgs.xz,
        pkgs.zstd,
      ],
  }
  in

  let kmod = {
    name = "kmod-34.2",
    tag = "Meson",
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
      build_dir = "build",
      setup_args = [
        "--buildtype=release",
        "-Dmanpages=false",
      ],
    },
    inputs = {
      image = kmod_build_image,
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
