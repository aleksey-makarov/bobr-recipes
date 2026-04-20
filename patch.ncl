let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let patch_src =
    {
      name = "patch-src-2.8",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz",
        "https://mirrors.kernel.org/gnu/patch/patch-2.8.tar.xz",
      ],
      hash = "md5:149327a021d41c8f88d034eab41c039f",
      },
      inputs = {},
    }
  in

  let patch_gen1 =
    recipe.binary "patch-gen1-2.8" {
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.host_image pkgs.buildscript_autotools [patch_src]
  in

  let patch =
    recipe.binary "patch-2.8" {
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [patch_src]
  in

  {
    include [
      patch_src,
      patch_gen1,
      patch,
    ],
  }
