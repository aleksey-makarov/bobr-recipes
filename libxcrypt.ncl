let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libxcrypt_src = {
    name = "libxcrypt-src-4.4.38",
    tag = "Source",
    object_hash = "3e8fe066132eb4300604bb5769f9d80fdfe1d443025978ea867ecef693afacd0",
    origin = {
      type = "http",
      url = "https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz",
    },
  }
  in

  let libxcrypt_build_rootfs = {
    name = "libxcrypt-build-rootfs",
    tag = "TreeMerge",
    config = {},
    inputs =
      { base = pkgs.system_rootfs_2 }
      & recipe.numbered_inputs [
        pkgs.perl,
      ],
  }
  in

  let libxcrypt = {
    name = "libxcrypt-4.4.38",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--enable-hashes=strong,glibc",
        "--enable-obsolete-api=no",
        "--disable-static",
        "--disable-failure-tokens",
      ],
    },
    inputs = {
      rootfs = libxcrypt_build_rootfs,
      source = libxcrypt_src,
    },
  }
  in

  let libxcrypt_libs =
    recipe.split.libs libxcrypt "usr/lib/*.so*"
    & {
      deps = {
        build = [],
        runtime = [
          pkgs.glibc_libs,
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
