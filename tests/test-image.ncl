let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_image =
    recipe.text "buildscript-test-image" {
      kind = "build-script",
      source = import "test-image.sh" as 'Text,
    }
  in

  let test_build_image =
    recipe.binary "test-build-image" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "build-image",
      },
    } pkgs.build_image buildscript_test_image []
  in

  let test_build_image_2 =
    recipe.binary "test-build-image-2" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "build-image-2",
      },
    } pkgs.build_image_2 buildscript_test_image []
  in

  let test_bootstrap_image =
    recipe.binary "test-bootstrap-image" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "bootstrap-image",
      },
    } pkgs.bootstrap_image buildscript_test_image []
  in

  {
    include [test_build_image, test_build_image_2, test_bootstrap_image],
  }
