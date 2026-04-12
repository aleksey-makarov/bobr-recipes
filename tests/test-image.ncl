let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_image =
    recipe.text "buildscript-test-image" {
      executable = true,
      source = import "test-image.sh" as 'Text,
    }
  in

  let test_system_image_1 =
    recipe.binary "test-system-image-1" {
      script_config = {
        name = "system-image-1",
      },
    } pkgs.system_image_1 buildscript_test_image []
  in

  let test_system_image =
    recipe.binary "test-system-image" {
      script_config = {
        name = "system-image",
        check_live_usr = "true",
      },
    } pkgs.system_image buildscript_test_image []
  in

  let test_system_image_0 =
    recipe.binary "test-system-image-0" {
      script_config = {
        name = "system-image-0",
      },
    } pkgs.system_image_0 buildscript_test_image []
  in

  let test_system_image_python_image =
    recipe.image "test-system-image-python-image" {} pkgs.system_image [
      pkgs.python,
    ]
  in

  let test_system_image_python =
    recipe.binary "test-system-image-python" {
      script_config = {
        name = "system-image-python",
        check_python = "true",
      },
    } test_system_image_python_image buildscript_test_image []
  in

  {
    include [
      test_system_image_1,
      test_system_image,
      test_system_image_0,
      test_system_image_python,
    ],
  }
