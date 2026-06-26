let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libpipeline_src = {
    name = "libpipeline-src-1.5.8",
    tag = "Source",
    object_hash = "d60f9f8f20452ec2a2c421c1b92cc6978b5f9ae640cc3148a8251852f23ba08e",
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-1.5.8.tar.gz",
    },
  }
  in

  let libpipeline = {
    name = "libpipeline-1.5.8",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {},
    inputs = {
      source = libpipeline_src,
    },
  }
  in

  {
    include [
      libpipeline,
    ],
  }
