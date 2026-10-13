fun pkgs =>
  let libffi_src = {
    version | default = "3.6.0",
    name = "libffi-src-%{version}",
    tag = "Source",
    object_hash | default = "31ff1fe32deaebfbb388727f32677bb254bf2a41382c51464c0b1837c9ee9828",
    origin = {
      tag = "Http",
      url = "https://github.com/libffi/libffi/releases/download/v%{version}/libffi-%{version}.tar.gz",
    },
  }
  in

  let libffi = {
    name = "libffi-%{inputs.source.version}",
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
        # --with-gcc-arch=native passes -march=native, tuning to the build
        # host CPU: non-reproducible across machines and non-portable (older
        # target CPUs would SIGILL). Build a generic baseline library instead.
        "--without-gcc-arch",
      ],
    },
    inputs = {
      source = pkgs.libffi_src,
    },
  }
  in

  {
    include [
      libffi_src,
      libffi,
    ],
  }
