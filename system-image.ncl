let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let system_image_0 =
    recipe.image "system-image-0" {
      mode = "bootstrap",
    } null [
      pkgs.base_filesystem,
      pkgs.linux_headers,
      pkgs.glibc_gen1,
      pkgs.binutils_gen1,
      pkgs.gcc_gen1,
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

  let system_image_2 =
    recipe.image "system-image-2" {
      mode = "bootstrap",
    } null [
      pkgs.base_filesystem,
      pkgs.linux_headers,
      pkgs.glibc,
      pkgs.binutils,
      pkgs.gcc,
      pkgs.bash,
      pkgs.gawk,
      pkgs.bison,
      pkgs.make,
      pkgs.coreutils,
      pkgs.sed,
      pkgs.grep,
      pkgs.gzip,
      pkgs.tar,
      pkgs.patch,
      pkgs.findutils,
      pkgs.diffutils,
      pkgs.m4,
      pkgs.bc,
      pkgs.flex,
      pkgs.zlib,
      pkgs.elfutils,
    ]
  in

  let system_image =
    recipe.image "system-image" {} pkgs.system_image_2 [
      pkgs.python,
      pkgs.expat,
      pkgs.libffi,
    ]
  in

  {
    include [system_image_0, system_image_1, system_image_2, system_image],
  }
