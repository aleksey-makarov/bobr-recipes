fun pkgs =>
  let build_image_2 =
    store.bind pkgs.base_filesystem (fun base_filesystem =>
    store.bind pkgs.linux_headers_6_18_10 (fun linux_headers =>
    store.bind pkgs.glibc_2_42 (fun glibc =>
    store.bind pkgs.binutils_2_45 (fun binutils =>
    store.bind pkgs.gcc_15_2_0 (fun gcc =>
    store.bind pkgs.bash_gen1_5_3 (fun bash_gen1 =>
    store.bind pkgs.gawk_gen1_5_3_2 (fun gawk_gen1 =>
    store.bind pkgs.bison_gen1_3_8_2 (fun bison_gen1 =>
    store.bind pkgs.make_gen1_4_4_1 (fun make_gen1 =>
    store.bind pkgs.coreutils_gen1_9_7 (fun coreutils_gen1 =>
    store.bind pkgs.sed_gen1_4_9 (fun sed_gen1 =>
    store.bind pkgs.grep_gen1_3_12 (fun grep_gen1 =>
    store.bind pkgs.gzip_gen1_1_14 (fun gzip_gen1 =>
    store.bind pkgs.tar_gen1_1_35 (fun tar_gen1 =>
    store.bind pkgs.patch_gen1_2_8 (fun patch_gen1 =>
    store.bind pkgs.findutils_gen1_4_10_0 (fun findutils_gen1 =>
    store.bind pkgs.diffutils_gen1_3_12 (fun diffutils_gen1 =>
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
      bash_gen1,
      gawk_gen1,
      bison_gen1,
      make_gen1,
      coreutils_gen1,
      sed_gen1,
      grep_gen1,
      gzip_gen1,
      tar_gen1,
      patch_gen1,
      findutils_gen1,
      diffutils_gen1,
      m4_gen1,
      python_gen1,
    ])))))))))))))))))))
  in

  {
    include [build_image_2],
  }
