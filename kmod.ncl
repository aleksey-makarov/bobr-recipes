let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let kmod_src =
    {
      name = "kmod-src-34.2",
      tag = "Fetch",
      config = {
      url = "https://www.kernel.org/pub/linux/utils/kernel/kmod/kmod-34.2.tar.xz",
      hash = "md5:36f2cc483745e81ede3406fa55e1065a",
      },
      inputs = {},
    }
  in

  let kmod_build_image =
    recipe.image "kmod-build-image" {} pkgs.system_image [
      pkgs.openssl,
      pkgs.xz,
      pkgs.zstd,
    ]
  in

  let kmod =
    recipe.binary "kmod-34.2" {
      script_config = {
        pre_configure = "sed -i '/requires_private : libkmod_deps,/d' meson.build",
        build_dir = "build",
        setup_args = [
          "--buildtype=release",
          "-Dmanpages=false",
        ],
      },
    } kmod_build_image pkgs.buildscript_meson [kmod_src]
  in

  {
    include [
      kmod_src,
      kmod,
    ],
  }
