let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libxcrypt_src = {
    name = "libxcrypt-src-4.4.38",
    tag = "Source",
    object_hash = "312c70fc5072cf879077124cbec78e2b3e39263f5a35e0b0d2947142d2f279ee",
    origin = {
      type = "http",
      url = "https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz",
      unpack = true,
    },
    meta = {},
  }
  in

  let libxcrypt_build_image = {
    name = "libxcrypt-build-image",
    tag = "Image",
    config = { ref_name | default = "libxcrypt-build-image" } & {},
    inputs =
      { base = pkgs.system_image_2 }
      & recipe.numbered_inputs [
        pkgs.perl,
      ],
  }
  in

  let libxcrypt = {
    name = "libxcrypt-4.4.38",
    tag = "Autotools",
    config = {
      configure_args = [
        "--enable-hashes=strong,glibc",
        "--enable-obsolete-api=no",
        "--disable-static",
        "--disable-failure-tokens",
      ],
    },
    inputs = {
      image = libxcrypt_build_image,
      source = libxcrypt_src,
    },
  }
  in

  {
    include [
      libxcrypt_src,
      libxcrypt,
    ],
  }
