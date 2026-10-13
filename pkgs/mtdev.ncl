fun pkgs =>
  let mtdev_src = {
    version | default = "1.1.7",
    name = "mtdev-src-%{version}",
    tag = "Source",
    object_hash | default = "a107adad2101fecac54ac7f9f0e0a0dd155d954193da55c2340c97f2ff1d814e",
    origin = {
      tag = "Http",
      url = "https://bitmath.org/code/mtdev/mtdev-%{version}.tar.bz2",
    },
  }
  in

  # Multitouch protocol translation library; a required dependency of libinput.
  let mtdev = {
    name = "mtdev-%{inputs.source.version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = pkgs.mtdev_src,
    },
  }
  in

  {
    include [
      mtdev_src,
      mtdev,
    ],
  }
