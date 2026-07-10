let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let groff_src = {
    name = "groff-src-1.23.0",
    tag = "Source",
    object_hash = "6b9757f592b7518b4902eb6af7e54570bdccba37a871fddb2d30ae3863511c13",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz",
        "https://mirrors.kernel.org/gnu/groff/groff-1.23.0.tar.gz",
      ],
    },
  }
  in

  let groff = {
    name = "groff-1.23.0",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc,
        pkgs.perl,
      ],
    },
    config = {
      env = {
        PAGE = "A4",
      },
    },
    inputs = {
      source = groff_src,
    },
  }
  in

  {
    include [
      groff,
    ],
  }
