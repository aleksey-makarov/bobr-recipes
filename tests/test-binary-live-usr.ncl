let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_test_binary_live_usr =
    recipe.text "buildscript-test-binary-live-usr" {
      executable = true,
      source = import "test-binary-live-usr.sh" as 'Text,
    }
  in

  let test_binary_live_usr_system_image =
    recipe.binary "test-binary-live-usr-system-image" {
      script_config = {
        name = "binary-live-usr-system-image",
      },
    } pkgs.system_image buildscript_test_binary_live_usr []
  in

  {
    include [test_binary_live_usr_system_image],
  }
