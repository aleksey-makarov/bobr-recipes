let version = "1.1.7" in

fun pkgs =>
  let mtdev_src = {
    name = "mtdev-src-%{version}",
    tag = "Source",
    object_hash = "e9b5ad7ed14883d94a16a8e982af12dc65bf50db7c2579e9f65009b6e420e77d",
    origin = {
      tag = "Http",
      url = "https://bitmath.org/code/mtdev/mtdev-%{version}.tar.bz2",
    },
  }
  in

  # Multitouch protocol translation library; a required dependency of libinput.
  let mtdev = {
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
      source = mtdev_src,
    },
  }
  in

  {
    include [
      mtdev,
    ],
  }
