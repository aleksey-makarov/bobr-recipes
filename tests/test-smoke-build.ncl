fun pkgs =>
  let buildscript_test_smoke_build =
    store.text "buildscript-test-smoke-build" {
      kind = "build-script",
      source = import "test-smoke-build.sh" as 'Text,
    }
  in

  let smoke_build =
    fun name deps =>
      store.bind buildscript_test_smoke_build (fun script =>
      store.bind pkgs.host_image (fun image =>
      store.bind (store.sequence_ deps) (fun _ =>
      store.binary name {
        kind = "binary-output",
        optimize = "size",
      } image script [])))
  in

  let test_smoke_build =
    smoke_build "test-smoke-build" [
      pkgs.bootstrap_image,
      pkgs.build_image,
      pkgs.build_image_2,
    ]
  in

  {
    include [test_smoke_build],
  }
