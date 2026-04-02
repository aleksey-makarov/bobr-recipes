let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_reports =
    recipe.text "buildscript-test-reports" {
      kind = "build-script",
      source = import "test-reports.sh" as 'Text,
    }
  in

  let test_reports =
    recipe.binary "test-reports" {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_test_reports [
      pkgs.test_system_image_0,
      pkgs.test_system_image,
      pkgs.test_system_image_1,
    ]
  in

  {
    include [test_reports],
  }
