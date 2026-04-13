let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let automake_src =
    recipe.fetch "automake-src-1.18.1" {
      url = [
        "https://ftp.gnu.org/gnu/automake/automake-1.18.1.tar.xz",
        "https://mirrors.kernel.org/gnu/automake/automake-1.18.1.tar.xz",
      ],
      hash = "md5:cea31dbf1120f890cbf2a3032cfb9a68",
    }
  in

  let automake =
    build.build_autotools {
      name = "automake-1.18.1",
      sources = [automake_src],
      script_config = {
        configure_args = [
          "--docdir=/usr/share/doc/automake-1.18.1",
        ],
      },
    }
  in

  {
    include [
      automake_src,
      automake,
    ],
  }
