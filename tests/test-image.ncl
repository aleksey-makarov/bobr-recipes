let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_image = {
    name = "buildscript-test-image",
    tag = "Text",
    config = {
      executable = true,
      source = import "test-image.sh" as 'Text,
    },
    inputs = {},
  }
  in

  let test_system_image_0 =
    recipe.binary
      "test-system-image-0"
      {
        script_config = {
          check_live_usr = "true",
          name = "system-image-0",
        },
      }
      pkgs.system_image_0
      buildscript_test_image
      []
  in

  let test_system_image_1 =
    recipe.binary
      "test-system-image-1"
      {
        script_config = {
          name = "system-image-1",
        },
      }
      pkgs.system_image_1
      buildscript_test_image
      []
  in

  let test_system_image_2 =
    recipe.binary
      "test-system-image-2"
      {
        script_config = {
          name = "system-image-2",
          check_live_usr = "true",
        },
      }
      pkgs.system_image_2
      buildscript_test_image
      []
  in

  let test_system_image =
    recipe.binary
      "test-system-image"
      {
        script_config = {
          name = "system-image",
          check_python = "true",
        },
      }
      pkgs.system_image
      buildscript_test_image
      []
  in

  {
    include [
      test_system_image_0,
      test_system_image_1,
      test_system_image_2,
      test_system_image,
    ],
  }
