fun pkgs =>
  let buildscript_test_reports =
    store.text "buildscript-test-reports" {
      kind = "build-script",
      source = import "test-reports.sh" as 'Text,
    }
  in

  let test_reports =
    store.bind buildscript_test_reports (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.bind pkgs.test_bootstrap_image (fun test_bootstrap_image =>
    store.bind pkgs.test_build_image_2 (fun test_build_image_2 =>
    store.bind pkgs.test_build_image (fun test_build_image =>
    store.binary "test-reports" {
      kind = "binary-output",
      optimize = "size",
    } image script [test_bootstrap_image, test_build_image_2, test_build_image])))))
  in

  {
    include [test_reports],
  }
