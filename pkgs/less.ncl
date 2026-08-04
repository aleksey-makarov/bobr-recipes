fun pkgs =>
  let less_src = fun version => fun hash => {
    name = "less-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.greenwoodsoftware.com/less/less-%{version}.tar.gz",
    },
  }
  in

  let less = {
    version | default = "679",
    source_object_hash | default = "9b68820c34fa8a0af6b0e01b74f0298bcdd40a0489c61649b47058908a153d78",
    name = "less-%{version}",
    tag = "Autotools",
    deps = {
      build = [
        pkgs.ncurses,
      ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.ncurses_libs,
      ],
    },
    config = {
      configure_args = [
        "--sysconfdir=/etc",
      ],
    },
    inputs = {
      source = less_src version source_object_hash,
    },
  }
  in

  {
    include [
      less,
    ],
  }
