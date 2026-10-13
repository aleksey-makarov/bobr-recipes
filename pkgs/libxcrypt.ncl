let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let libxcrypt_src = {
    version | default = "4.5.2",
    name = "libxcrypt-src-%{version}",
    tag = "Source",
    object_hash | default = "71513a31c01a428bccd5367a32fd95f115d6dac50fb5b60c779d5c7942aec071",
    origin = {
      tag = "Http",
      url = "https://github.com/besser82/libxcrypt/releases/download/v%{version}/libxcrypt-%{version}.tar.xz",
    },
  }
  in

  let libxcrypt = {
    name = "libxcrypt-%{inputs.source.version}",
    tag = "Autotools",
    # perl -- the only extra the old build rootfs added on top of the toolchain
    # -- is already a default Autotools build dep, so deps.build stays empty.
    deps = {
      build = [],
      runtime = [
        pkgs.c_runtime,
      ],
    },
    config = {
      configure_args = [
        "--enable-hashes=strong,glibc",
        "--enable-obsolete-api=no",
        "--disable-static",
        "--disable-failure-tokens",
      ],
    },
    inputs = {
      source = pkgs.libxcrypt_src,
    },
  }
  in

  let libxcrypt_libs =
    recipe.split.libs pkgs.libxcrypt "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.c_runtime,
        ],
      },
    }
  in

  {
    include [
      libxcrypt_src,
      libxcrypt,
      libxcrypt_libs,
    ],
  }
