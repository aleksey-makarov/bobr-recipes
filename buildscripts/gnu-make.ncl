let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_gnu_make =
    recipe.text "buildscript-gnu-make" {
      executable = true,
      source = import "gnu-make.sh" as 'Text,
    }
  in

  {
    include [
      buildscript_gnu_make,
    ],
  }
