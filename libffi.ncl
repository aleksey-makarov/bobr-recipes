let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libffi_src = {
    name = "libffi-src-3.5.2",
    tag = "Fetch",
    config = {
      url = "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz",
      hash = "md5:92af9efad4ba398995abf44835c5d9e9",
    },
    inputs = {},
  }
  in

  let libffi =
    recipe.binary
      "libffi-3.5.2"
      {
        script_config = {
          configure_args = [
            "--disable-static",
            "--with-gcc-arch=native",
          ],
        },
      }
      pkgs.system_image_2
      pkgs.buildscript_autotools
      [libffi_src]
  in

  {
    include [
      libffi_src,
      libffi,
    ],
  }
