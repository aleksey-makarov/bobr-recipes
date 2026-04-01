let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bootstrap_image =
    recipe.image "bootstrap-image" {
      mode = "bootstrap",
    } null [
      pkgs.base_filesystem,
      pkgs.linux_headers_6_18_10,
      pkgs.glibc_gen1_2_42,
      pkgs.binutils_gen1_2_45,
      pkgs.gcc_gen1_15_2_0,
      pkgs.bash_gen1_5_3,
      pkgs.gawk_gen1_5_3_2,
      pkgs.bison_gen1_3_8_2,
      pkgs.make_gen1_4_4_1,
      pkgs.coreutils_gen1_9_7,
      pkgs.sed_gen1_4_9,
      pkgs.grep_gen1_3_12,
      pkgs.gzip_gen1_1_14,
      pkgs.tar_gen1_1_35,
      pkgs.patch_gen1_2_8,
      pkgs.findutils_gen1_4_10_0,
      pkgs.diffutils_gen1_3_12,
      pkgs.m4_gen1_1_4_20,
      pkgs.python_gen1_3_13_7,
    ]
  in

  {
    include [bootstrap_image],
  }
