let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let groff_src =
    recipe.fetch "groff-src-1.23.0" {
      url = [
        "https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz",
        "https://mirrors.kernel.org/gnu/groff/groff-1.23.0.tar.gz",
      ],
      hash = "md5:5e4f40315a22bb8a158748e7d5094c7d",
    }
  in

  let groff =
    build.build_autotools {
      name = "groff-1.23.0",
      sources = [groff_src],
      script_config = {
        configure_args = [],
        env = {
          PAGE = "A4",
        },
      },
    }
  in

  {
    include [
      groff_src,
      groff,
    ],
  }
