let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let make_src =
    recipe.fetch "make-src-4.4.1" {
      url = [
        "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
        "https://mirrors.kernel.org/gnu/make/make-4.4.1.tar.gz",
      ],
      hash = "md5:c8469a3713cbbe04d955d4ae4be23eeb",
    }
  in

  let make_gen1 =
    recipe.binary "make-gen1-4.4.1" {
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.host_image pkgs.buildscript_autotools [make_src]
  in

  let make =
    recipe.binary "make-4.4.1" {
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [make_src]
  in

  {
    include [
      make_src,
      make_gen1,
      make,
    ],
  }
