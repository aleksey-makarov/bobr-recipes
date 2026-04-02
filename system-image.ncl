let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let system_image =
    recipe.image "system-image" {
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
      pkgs.python_gen1,
    ]
  in

  {
    include [system_image],
  }
