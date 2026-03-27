fun pkgs =>
  let buildscript_test_smoke_build =
    store.text "buildscript-test-smoke-build" {
      kind = "build-script",
      source = import "test-smoke-build.sh" as 'Text,
    }
  in

  let test_smoke_build =
    store.bind buildscript_test_smoke_build (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.bind pkgs.bootstrap_image (fun bootstrap_image =>
    store.bind pkgs.build_image (fun build_image =>
    store.bind pkgs.build_image_2 (fun build_image_2 =>
    store.binary "test-smoke-build" {
      kind = "binary-output",
      optimize = "size",
    } image script [])))))
  in

  {
    include [test_smoke_build],
  }
