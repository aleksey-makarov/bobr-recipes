let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libffi_src = {
    name = "libffi-src-3.5.2",
    tag = "Source",
    object_hash = "afcddd52785db63850239f2d8c39472af103df9a251b35fd03475197eddaeed0",
    origin = {
      tag = "Http",
      url = "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz",
    },
  }
  in

  let libffi = {
    name = "libffi-3.5.2",
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
        # --with-gcc-arch=native passes -march=native, tuning to the build
        # host CPU: non-reproducible across machines and non-portable (older
        # target CPUs would SIGILL). Build a generic baseline library instead.
        "--without-gcc-arch",
      ],
    },
    inputs = {
      source = libffi_src,
    },
  }
  in

  {
    include [
      libffi,
    ],
  }
