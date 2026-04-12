let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zstd_src =
    recipe.fetch "zstd-src-1.5.7" {
      url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz",
      hash = "md5:780fc1896922b1bc52a4e90980cdda48",
    }
  in

  let zstd =
    recipe.binary "zstd-1.5.7" {
      script_config = {
        make_args = [
          "prefix=/usr",
        ],
        post_install = "rm -fv \"/out/${out}/usr/lib/libzstd.a\"",
      },
    } pkgs.system_image_2 pkgs.buildscript_gnu_make [zstd_src]
  in

  {
    include [
      zstd_src,
      zstd,
    ],
  }
