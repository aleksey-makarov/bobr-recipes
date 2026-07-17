let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libpipeline_src = fun version => fun hash => {
    name = "libpipeline-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://download.savannah.gnu.org/releases/libpipeline/libpipeline-%{version}.tar.gz",
    },
  }
  in

  let libpipeline = {
    version | default = "1.5.8",
    source_object_hash | default = "1b1203ca152ccd63983c3f2112f7fe6fa5afd453218ede5153d1b31e11bb8405",
    name = "libpipeline-%{version}",
    tag = "AutotoolsInstall",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {},
    inputs = {
      source = libpipeline_src version source_object_hash,
    },
  }
  in

  {
    include [
      libpipeline,
    ],
  }
