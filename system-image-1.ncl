let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let system_image_1 =
    recipe.image "system-image-1" {
      mode = "bootstrap",
    } null [
      pkgs.base_filesystem,
      pkgs.linux_headers,
      pkgs.glibc,
      pkgs.binutils,
      pkgs.gcc,
      pkgs.bash_gen1,
      pkgs.gawk_gen1,
      pkgs.bison_gen1,
      pkgs.make_gen1,
      pkgs.coreutils_gen1,
      pkgs.sed_gen1,
      pkgs.grep_gen1,
      pkgs.gzip_gen1,
      pkgs.tar_gen1,
      pkgs.patch_gen1,
      pkgs.findutils_gen1,
      pkgs.diffutils_gen1,
      pkgs.m4_gen1,
      pkgs.python_gen1,
    ]
  in

  {
    include [system_image_1],
  }
