let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gzip_src =
    {
      name = "gzip-src-1.14",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.xz",
        "https://mirrors.kernel.org/gnu/gzip/gzip-1.14.tar.xz",
      ],
      hash = "md5:4bf5a10f287501ee8e8ebe00ef62b2c2",
      },
      inputs = {},
    }
  in

  let gzip_gen1 =
    recipe.binary "gzip-gen1-1.14" {
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.host_image pkgs.buildscript_autotools [gzip_src]
  in

  let gzip =
    recipe.binary "gzip-1.14" {
      script_config = {
        configure_args = ["--disable-nls"],
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [gzip_src]
  in

  {
    include [
      gzip_src,
      gzip_gen1,
      gzip,
    ],
  }
