let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_gnu_make =
    {
      name = "buildscript-gnu-make",
      tag = "Text",
      config = {
      executable = true,
      source = import "gnu-make.sh" as 'Text,
      },
      inputs = {},
    }
  in

  {
    include [
      buildscript_gnu_make,
    ],
  }
