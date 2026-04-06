let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_autotools =
    recipe.text "buildscript-autotools" {
      executable = true,
      source = import "autotools.sh" as 'Text,
    }
  in

  {
    include [
      buildscript_autotools,
    ],
  }
