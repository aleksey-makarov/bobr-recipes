let recipe = import "recipe-lib.ncl" in
let hashes = {
  "4.4.38" = "3e8fe066132eb4300604bb5769f9d80fdfe1d443025978ea867ecef693afacd0",
  "4.5.2" = "61672cb1ce67e78a1c27e83b4b5d636e89dd0a2b71d5295fbf4e80beaf8fb5b1",
} in

fun pkgs =>
  let libxcrypt_src = fun version => {
    name = "libxcrypt-src-%{version}",
    tag = "Source",
    object_hash = hashes."%{version}",
    origin = {
      tag = "Http",
      url = "https://github.com/besser82/libxcrypt/releases/download/v%{version}/libxcrypt-%{version}.tar.xz",
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
    version | default = "4.5.2",
    name = "libxcrypt-%{version}",
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
      _rootfs = libxcrypt_build_rootfs,
      source = libxcrypt_src version,
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
      libxcrypt,
      libxcrypt_libs,
    ],
  }
