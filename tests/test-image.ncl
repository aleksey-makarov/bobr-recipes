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

  let test_system_image_2 =
    recipe.binary "test-system-image-2" {
      script_config = {
        name = "system-image-2",
        check_live_usr = "true",
      },
    } pkgs.system_image_2 buildscript_test_image []
  in

  let test_system_image_0 =
    recipe.binary "test-system-image-0" {
      script_config = {
        name = "system-image-0",
      },
    } pkgs.system_image_0 buildscript_test_image []
  in

  let test_system_image_2_python_image =
    recipe.image "test-system-image-2-python-image" {} pkgs.system_image_2 [
      pkgs.python,
      pkgs.expat,
      pkgs.libffi,
    ]
  in

  let test_system_image_2_python =
    recipe.binary "test-system-image-2-python" {
      script_config = {
        name = "system-image-2-python",
        check_python = "true",
      },
    } test_system_image_2_python_image buildscript_test_image []
  in

  {
    include [
      test_system_image_1,
      test_system_image_2,
      test_system_image_0,
      test_system_image_2_python,
    ],
  }
