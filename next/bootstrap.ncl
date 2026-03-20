fun pkgs =>
  let gcc_temp_build_image =
    store.bind pkgs.host_image (fun host_image =>
    store.bind pkgs.binutils_temp_2_45 (fun binutils_temp =>
    store.image "gcc-temp-build-image" {
      mode = "layered",
    } host_image [binutils_temp]))
  in

  let glibc_temp_build_image =
    store.bind pkgs.gcc_temp_build_image (fun gcc_temp_build_image =>
    store.bind pkgs.gcc_temp_15_2_0 (fun gcc_temp =>
    store.bind pkgs.linux_headers_temp_6_18_10 (fun linux_headers_temp =>
    store.bind pkgs.gawk_temp_5_3_2 (fun gawk_temp =>
    store.bind pkgs.bison_temp_3_8_2 (fun bison_temp =>
    store.image "glibc-temp-build-image" {
      mode = "layered",
    } gcc_temp_build_image [gcc_temp, linux_headers_temp, gawk_temp, bison_temp])))))
  in

  let stage1_userland_build_image =
    store.bind pkgs.glibc_temp_build_image (fun glibc_temp_build_image =>
    store.bind pkgs.glibc_temp_2_42 (fun glibc_temp =>
    store.image "stage1-userland-build-image" {
      mode = "layered",
    } glibc_temp_build_image [glibc_temp]))
  in

  {
    include [gcc_temp_build_image, glibc_temp_build_image, stage1_userland_build_image],
  }
