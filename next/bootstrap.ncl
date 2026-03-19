fun pkgs =>
  let gcc_temp_build_image =
    store.bind pkgs.host_image (fun host_image =>
    store.bind pkgs.binutils_temp_2_45 (fun binutils_temp =>
    store.image "gcc-temp-build-image" {
      mode = "layered",
    } host_image [binutils_temp]))
  in

  {
    include [gcc_temp_build_image],
  }
