let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let patch_src =
    recipe.fetch "patch-src-2.8" {
      url = [
        "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz",
        "https://mirrors.kernel.org/gnu/patch/patch-2.8.tar.xz",
      ],
      hash = "md5:149327a021d41c8f88d034eab41c039f",
    }
  in

  let patch_gen1 =
    recipe.binary "patch-gen1-2.8" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.host_image pkgs.buildscript_autotools [patch_src]
  in

  let patch =
    build.build_autotools {
      name = "patch-2.8",
      sources = [patch_src],
      script_config = {
        configure_args = ["--disable-nls"],
      },
    }
  in

  {
    include [
      patch_src,
      patch_gen1,
      patch,
    ],
  }
