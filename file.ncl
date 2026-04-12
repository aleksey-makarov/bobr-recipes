let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let file_src =
    recipe.fetch "file-src-5.46" {
      url = "https://astron.com/pub/file/file-5.46.tar.gz",
      hash = "md5:459da2d4b534801e2e2861611d823864",
    }
  in

  let file_build_image =
    recipe.image "file-build-image" {} pkgs.system_image_2 [
      pkgs.bzip2,
      pkgs.xz,
    ]
  in

  let file =
    recipe.binary "file-5.46" {
      script_config = {
        configure_args = [],
      },
    } file_build_image pkgs.buildscript_autotools [file_src]
  in

  {
    include [
      file_src,
      file,
    ],
  }
