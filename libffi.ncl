let recipe = import "recipe-lib.ncl" in
let hashes = {
  "3.5.2" = "afcddd52785db63850239f2d8c39472af103df9a251b35fd03475197eddaeed0",
  "3.6.0" = "85fb6048358a84f27b394991a14aec0f1cb8c686c75440f44bd973490ef08600",
}
in

fun pkgs =>
  let libffi_src = fun version =>
    {
      name = "libffi-src-%{version}",
      tag = "Source",
      object_hash = hashes."%{version}",
      origin = {
        tag = "Http",
        url = "https://github.com/libffi/libffi/releases/download/v%{version}/libffi-%{version}.tar.gz",
      },
    }
  in

  let libffi = {
    version | default = "3.6.0",
    name = "libffi-%{version}",
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
      source = libffi_src version,
    },
  }
  in

  {
    include [
      libffi,
    ],
  }
