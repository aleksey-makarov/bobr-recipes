let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let libpipeline_src =
    recipe.fetch "libpipeline-src-1.5.8" {
      url = "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz",
      hash = "md5:17ac6969b2015386bcb5d278a08a40b5",
    }
  in

  let libpipeline =
    build.build_autotools {
      name = "libpipeline-1.5.8",
      sources = [libpipeline_src],
      script_config = {
        configure_args = [],
      },
    }
  in

  {
    include [
      libpipeline_src,
      libpipeline,
    ],
  }
