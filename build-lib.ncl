let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build_autotools_with =
    fun image =>
    fun { name, sources, script_config } =>
      recipe.binary name {
        kind = "binary-output",
        optimize = "size",
        include script_config,
      } image pkgs.buildscript_autotools sources
  in

  let build_autotools =
    build_autotools_with pkgs.system_image_1
  in

  let build_bootstrap_autotools =
    build_autotools_with pkgs.system_image_0
  in

  {
    include [
      build_autotools,
      build_bootstrap_autotools,
    ],
  }
