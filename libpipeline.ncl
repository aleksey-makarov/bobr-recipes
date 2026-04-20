let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libpipeline_src =
    {
      name = "libpipeline-src-1.5.8",
      tag = "Fetch",
      config = {
      url = "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz",
      hash = "md5:17ac6969b2015386bcb5d278a08a40b5",
      },
      inputs = {},
    }
  in

  let libpipeline =
    let script_config = {
        configure_args = [],
      }
    in
    recipe.binary "libpipeline-1.5.8" {
      include script_config,
    } pkgs.system_image pkgs.buildscript_autotools [libpipeline_src]
  in

  {
    include [
      libpipeline_src,
      libpipeline,
    ],
  }
