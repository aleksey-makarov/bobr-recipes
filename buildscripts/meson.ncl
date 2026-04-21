let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_meson = {
    name = "buildscript-meson",
    tag = "Text",
    config = {
      executable = true,
      source = import "meson.sh" as 'Text,
    },
    inputs = {},
  }
  in

  {
    include [
      buildscript_meson,
    ],
  }
