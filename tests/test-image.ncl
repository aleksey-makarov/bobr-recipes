fun pkgs =>
  let buildscript_test_image =
    store.text "buildscript-test-image" {
      kind = "build-script",
      source = import "test-image.sh" as 'Text,
    }
  in

  let test_build_image =
    store.bind buildscript_test_image (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "test-build-image" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "build-image",
      },
    } image script []))
  in

  let test_build_image_2 =
    store.bind buildscript_test_image (fun script =>
    store.bind pkgs.build_image_2 (fun image =>
    store.binary "test-build-image-2" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "build-image-2",
      },
    } image script []))
  in

  let test_bootstrap_image =
    store.bind buildscript_test_image (fun script =>
    store.bind pkgs.bootstrap_image (fun image =>
    store.binary "test-bootstrap-image" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        name = "bootstrap-image",
      },
    } image script []))
  in

  {
    include [test_build_image, test_build_image_2, test_bootstrap_image],
  }
