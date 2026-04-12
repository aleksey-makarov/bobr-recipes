let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build_autotools_with =
    fun image =>
    fun { name, sources, script_config } =>
      recipe.binary name {
          include script_config,
      } image pkgs.buildscript_autotools sources
  in

  let build_make_with =
    fun image =>
    fun { name, sources, script_config } =>
      recipe.binary name {
          include script_config,
      } image pkgs.buildscript_gnu_make sources
  in

  let build_autotools =
    build_autotools_with pkgs.system_image
  in

  # let build_make =
  #   build_make_with pkgs.system_image_2
  # in

  {
    include [
      build_autotools,
      # build_make,
    ],
  }
