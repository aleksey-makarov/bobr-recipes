let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_reports =
    {
      name = "buildscript-test-reports",
      tag = "Text",
      config = {
      executable = true,
      source = import "test-reports.sh" as 'Text,
      },
      inputs = {},
    }
  in

  let test_reports =
    recipe.binary "test-reports" {
    } pkgs.host_image buildscript_test_reports [
      pkgs.test_system_image_0,
      pkgs.test_system_image_1,
      pkgs.test_system_image_2,
      pkgs.test_system_image,
    ]
  in

  {
    include [test_reports],
  }
