let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libpipeline_src = {
    name = "libpipeline-src-1.5.8",
    tag = "Source",
    object_hash = "1b1203ca152ccd63983c3f2112f7fe6fa5afd453218ede5153d1b31e11bb8405",
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
