let recipe = import "recipe-lib.ncl" in
let hashes = {
  "4.4.38" = "80304b9c306ea799327f01d9a7549bdb28317789182631f1b54f4511b4206dd6",
  "4.5.2" = "71513a31c01a428bccd5367a32fd95f115d6dac50fb5b60c779d5c7942aec071",
}
in

fun pkgs =>
  let libxcrypt_src = fun version =>
    {
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
