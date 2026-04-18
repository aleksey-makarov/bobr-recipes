let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libxcrypt_src =
    recipe.fetch "libxcrypt-src-4.4.38" {
      url = "https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz",
      hash = "md5:1796a5d20098e9dd9e3f576803c83000",
    }
  in

  let libxcrypt_build_image =
    recipe.image "libxcrypt-build-image" {} pkgs.system_image_2 [
      pkgs.perl,
    ]
  in

  let libxcrypt =
    recipe.binary "libxcrypt-4.4.38" {
      script_config = {
        configure_args = [
          "--enable-hashes=strong,glibc",
          "--enable-obsolete-api=no",
          "--disable-static",
          "--disable-failure-tokens",
        ],
      },
    } libxcrypt_build_image pkgs.buildscript_autotools [libxcrypt_src]
  in

  {
    include [
      libxcrypt_src,
      libxcrypt,
    ],
  }
