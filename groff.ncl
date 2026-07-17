let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let groff_src = fun version => fun hash => {
    name = "groff-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/groff/groff-%{version}.tar.gz",
        "https://mirrors.kernel.org/gnu/groff/groff-%{version}.tar.gz",
      ],
    },
  }
  in

  let groff = {
    version | default = "1.23.0",
    source_object_hash | default = "6b9757f592b7518b4902eb6af7e54570bdccba37a871fddb2d30ae3863511c13",
    name = "groff-%{version}",
    tag = "AutotoolsInstall",
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
      source = groff_src version source_object_hash,
    },
  }
  in

  {
    include [
      groff,
    ],
  }
