let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_perl_module =
    recipe.text "buildscript-perl-module" {
      executable = true,
      source = import "perl-module.sh" as 'Text,
    }
  in

  {
    include [
      buildscript_perl_module,
    ],
  }
