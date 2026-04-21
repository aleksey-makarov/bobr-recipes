let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_perl_module = {
    name = "buildscript-perl-module",
    tag = "Text",
    config = {
      executable = true,
      source = import "perl-module.sh" as 'Text,
    },
    inputs = {},
  }
  in

  {
    include [
      buildscript_perl_module,
    ],
  }
