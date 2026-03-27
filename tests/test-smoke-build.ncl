fun pkgs =>
  let test_smoke_build =
    store.sequence_ [
      pkgs.bootstrap_image,
      pkgs.build_image,
      pkgs.build_image_2,
    ]
  in

  {
    include [test_smoke_build],
  }
