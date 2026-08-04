
fun pkgs =>
  let mtdev_src = fun version => fun hash => {
    name = "mtdev-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://bitmath.org/code/mtdev/mtdev-%{version}.tar.bz2",
    },
  }
  in

  # Multitouch protocol translation library; a required dependency of libinput.
  let mtdev = {
    version | default = "1.1.7",
    source_object_hash | default = "a107adad2101fecac54ac7f9f0e0a0dd155d954193da55c2340c97f2ff1d814e",
    name = "mtdev-%{version}",
    tag = "Autotools",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      configure_args = [
        "--disable-static",
      ],
    },
    inputs = {
      source = mtdev_src version source_object_hash,
    },
  }
  in

  {
    include [
      mtdev,
    ],
  }
