let recipe = import "recipe-lib.ncl" in
let hashes = {
  "3.5.2" = "f3a3082a23b37c293a4fcd1053147b371f2ff91fa7ea1b2a52e335676bac82dc",
  "3.6.0" = "31ff1fe32deaebfbb388727f32677bb254bf2a41382c51464c0b1837c9ee9828",
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
