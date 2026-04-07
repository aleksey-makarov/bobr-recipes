let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bc_src =
    recipe.fetch "bc-src-7.0.3" {
      url = "https://github.com/gavinhoward/bc/archive/c8dabac65d39fd527a9264a5e505a99b1d8df3d8.tar.gz",
      hash = "sha256:efc1df54c5378be62a93662e34f6829af1738a858211bd51c8d9b6c0892825ac",
    }
  in

  let bc =
    recipe.binary "bc-7.0.3" {
      script_config = {
        configure_args = [
          "--disable-history",
          "--disable-man-pages",
          "--disable-nls",
        ],
      },
    } pkgs.host_image pkgs.buildscript_autotools [bc_src]
  in

  {
    include [
      bc_src,
      bc,
    ],
  }
