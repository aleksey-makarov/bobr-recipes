let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_image =
    recipe.text "buildscript-test-image" {
      kind = "build-script",
      source = import "test-image.sh" as 'Text,
    }
  in

  let test_system_image_1 =
    recipe.binary "test-system-image-1" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "system-image-1",
      },
    } pkgs.system_image_1 buildscript_test_image []
  in

  let test_system_image =
    recipe.binary "test-system-image" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "system-image",
      },
    } pkgs.system_image buildscript_test_image []
  in

  let test_system_image_0 =
    recipe.binary "test-system-image-0" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "system-image-0",
      },
    } pkgs.system_image_0 buildscript_test_image []
  in

  {
    include [test_system_image_1, test_system_image, test_system_image_0],
  }
