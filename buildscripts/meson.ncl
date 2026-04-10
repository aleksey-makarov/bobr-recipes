let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_meson =
    recipe.text "buildscript-meson" {
      executable = true,
      source = import "meson.sh" as 'Text,
    }
  in

  {
    include [
      buildscript_meson,
    ],
  }
