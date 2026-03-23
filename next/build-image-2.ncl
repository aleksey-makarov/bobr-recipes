fun pkgs =>
  let build_image_2 =
    store.bind pkgs.base_filesystem (fun base_filesystem =>
    store.bind pkgs.linux_headers_6_18_10 (fun linux_headers =>
    store.bind pkgs.glibc_2_42 (fun glibc =>
    store.bind pkgs.binutils_2_45 (fun binutils =>
    store.bind pkgs.gcc_15_2_0 (fun gcc =>
    store.bind pkgs.bash_5_3 (fun bash =>
    store.bind pkgs.gawk_gen1_5_3_2 (fun gawk_gen1 =>
    store.bind pkgs.bison_gen1_3_8_2 (fun bison_gen1 =>
    store.bind pkgs.make_4_4_1 (fun make =>
    store.bind pkgs.coreutils_9_7 (fun coreutils =>
    store.bind pkgs.sed_4_9 (fun sed =>
    store.bind pkgs.grep_3_12 (fun grep =>
    store.bind pkgs.gzip_gen1_1_14 (fun gzip_gen1 =>
    store.bind pkgs.tar_gen1_1_35 (fun tar_gen1 =>
    store.bind pkgs.patch_2_8 (fun patch =>
    store.bind pkgs.findutils_4_10_0 (fun findutils =>
    store.bind pkgs.diffutils_3_12 (fun diffutils =>
    store.bind pkgs.m4_gen1_1_4_20 (fun m4_gen1 =>
    store.bind pkgs.python_gen1_3_13_7 (fun python_gen1 =>
    store.image "build-image-2" {
      mode = "bootstrap",
    } null [
      base_filesystem,
      linux_headers,
      glibc,
      binutils,
      gcc,
      bash,
      gawk_gen1,
      bison_gen1,
      make,
      coreutils,
      sed,
      grep,
      gzip_gen1,
      tar_gen1,
      patch,
      findutils,
      diffutils,
      m4_gen1,
      python_gen1,
    ])))))))))))))))))))
  in

  {
    include [build_image_2],
  }
