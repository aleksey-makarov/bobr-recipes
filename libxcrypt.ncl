let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libxcrypt_src = {
    name = "libxcrypt-src-4.4.38",
    tag = "Fetch",
    config = {
      url = "https://github.com/besser82/libxcrypt/releases/download/v4.4.38/libxcrypt-4.4.38.tar.xz",
      hash = "md5:1796a5d20098e9dd9e3f576803c83000",
    },
    inputs = {},
  }
  in

  let libxcrypt_build_image = {
    name = "libxcrypt-build-image",
    tag = "Image",
    config = { ref_name | default = "libxcrypt-build-image" } & {},
    inputs = {
      base = pkgs.system_image_2,
      inputs = [
        pkgs.perl,
      ],
    },
  }
  in

  let libxcrypt =
    recipe.binary
      "libxcrypt-4.4.38"
      {
        script_config = {
          configure_args = [
            "--enable-hashes=strong,glibc",
            "--enable-obsolete-api=no",
            "--disable-static",
            "--disable-failure-tokens",
          ],
        },
      }
      libxcrypt_build_image
      pkgs.buildscript_autotools
      [libxcrypt_src]
  in

  {
    include [
      libxcrypt_src,
      libxcrypt,
    ],
  }
