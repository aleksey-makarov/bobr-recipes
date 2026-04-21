let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let groff_src = {
    name = "groff-src-1.23.0",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz",
        "https://mirrors.kernel.org/gnu/groff/groff-1.23.0.tar.gz",
      ],
      hash = "md5:5e4f40315a22bb8a158748e7d5094c7d",
    },
    inputs = {},
  }
  in

  let groff =
    let script_config = {
      configure_args = [],
      env = {
        PAGE = "A4",
      },
    }
    in
    recipe.binary
      "groff-1.23.0"
      {
        include script_config,
      }
      pkgs.system_image
      pkgs.buildscript_autotools
      [groff_src]
  in

  {
    include [
      groff_src,
      groff,
    ],
  }
