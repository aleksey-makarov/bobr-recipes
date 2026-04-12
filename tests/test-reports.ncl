let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_reports =
    recipe.text "buildscript-test-reports" {
      executable = true,
      source = import "test-reports.sh" as 'Text,
    }
  in

  let test_reports =
    recipe.binary "test-reports" {
    } pkgs.host_image buildscript_test_reports [
      pkgs.test_system_image_0,
      pkgs.test_system_image_2,
      pkgs.test_system_image_1,
      pkgs.test_system_image_2_python,
    ]
  in

  {
    include [test_reports],
  }
