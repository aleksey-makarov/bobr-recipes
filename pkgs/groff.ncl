fun pkgs =>
  let groff_src = {
    version | default = "1.23.0",
    name = "groff-src-%{version}",
    tag = "Source",
    object_hash | default = "6b9757f592b7518b4902eb6af7e54570bdccba37a871fddb2d30ae3863511c13",
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
    name = "groff-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
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
      source = pkgs.groff_src,
    },
  }
  in

  {
    include [
      groff_src,
      groff,
    ],
  }
