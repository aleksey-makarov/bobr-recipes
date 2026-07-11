let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libxcrypt_src = fun version =>
    fun hash =>
    {
      name = "libxcrypt-src-%{version}",
      tag = "Source",
      object_hash = hash,
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
    source_object_hash | default = "71513a31c01a428bccd5367a32fd95f115d6dac50fb5b60c779d5c7942aec071",
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
      source = libxcrypt_src version source_object_hash,
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
