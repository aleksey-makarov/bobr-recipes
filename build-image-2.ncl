let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build_image_2 =
    recipe.image "build-image-2" {
      mode = "bootstrap",
    } null [
      pkgs.base_filesystem,
      pkgs.linux_headers_6_18_10,
      pkgs.glibc_2_42,
      pkgs.binutils_2_45,
      pkgs.gcc_15_2_0,
      pkgs.bash_5_3,
      pkgs.gawk_5_3_2,
      pkgs.bison_3_8_2,
      pkgs.make_4_4_1,
      pkgs.coreutils_9_7,
      pkgs.sed_4_9,
      pkgs.grep_3_12,
      pkgs.gzip_1_14,
      pkgs.tar_1_35,
      pkgs.patch_2_8,
      pkgs.findutils_4_10_0,
      pkgs.diffutils_3_12,
      pkgs.m4_1_4_20,
      pkgs.python_gen1_3_13_7,
    ]
  in

  {
    include [build_image_2],
  }
