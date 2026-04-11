let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let libxcrypt_src =
    recipe.fetch "libxcrypt-src-4.4.38" {
      url = "https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz",
      hash = "md5:1796a5d20098e9dd9e3f576803c83000",
    }
  in

  let libxcrypt =
    build.build_autotools {
      name = "libxcrypt-4.4.38",
      sources = [libxcrypt_src],
      script_config = {
        configure_args = [
          "--enable-hashes=strong,glibc",
          "--enable-obsolete-api=no",
          "--disable-static",
          "--disable-failure-tokens",
        ],
      },
    }
  in

  {
    include [
      libxcrypt_src,
      libxcrypt,
    ],
  }
