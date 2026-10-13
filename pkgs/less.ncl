fun pkgs =>
  let less_src = {
    version | default = "679",
    name = "less-src-%{version}",
    tag = "Source",
    object_hash | default = "9b68820c34fa8a0af6b0e01b74f0298bcdd40a0489c61649b47058908a153d78",
    origin = {
      tag = "Http",
      url = "https://www.greenwoodsoftware.com/less/less-%{version}.tar.gz",
    },
  }
  in

  let less = {
    name = "less-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
      ],
      runtime = [
        pkgs.c_runtime,
        pkgs.ncurses_libs,
      ],
    },
    config = {
      configure_args = [
        "--sysconfdir=/etc",
      ],
    },
    inputs = {
      source = pkgs.less_src,
    },
  }
  in

  {
    include [
      less_src,
      less,
    ],
  }
