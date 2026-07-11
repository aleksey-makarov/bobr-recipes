let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libffi_src = fun version =>
    fun hash =>
    {
      name = "libffi-src-%{version}",
      tag = "Source",
      object_hash = hash,
      origin = {
        tag = "Http",
        url = "https://github.com/libffi/libffi/releases/download/v%{version}/libffi-%{version}.tar.gz",
      },
    }
  in

  let libffi = {
    version | default = "3.6.0",
    source_object_hash | default = "31ff1fe32deaebfbb388727f32677bb254bf2a41382c51464c0b1837c9ee9828",
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
      source = libffi_src version source_object_hash,
    },
  }
  in

  {
    include [
      libffi,
    ],
  }
