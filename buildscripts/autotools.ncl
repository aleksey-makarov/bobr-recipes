let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_autotools =
    recipe.text "buildscript-autotools" {
      kind = "build-script",
      source = import "autotools.sh" as 'Text,
    }
  in

  {
    include [
      buildscript_autotools,
    ],
  }
