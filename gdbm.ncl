let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let gdbm_src =
    recipe.fetch "gdbm-src-1.26" {
      url = [
        "https://ftp.gnu.org/gnu/gdbm/gdbm-1.26.tar.gz",
        "https://mirrors.kernel.org/gnu/gdbm/gdbm-1.26.tar.gz",
      ],
      hash = "md5:aaa600665bc89e2febb3c7bd90679115",
    }
  in

  let gdbm =
    build.build_autotools {
      name = "gdbm-1.26",
      sources = [gdbm_src],
      script_config = {
        configure_args = [
          "--disable-static",
          "--enable-libgdbm-compat",
        ],
      },
    }
  in

  {
    include [
      gdbm_src,
      gdbm,
    ],
  }
