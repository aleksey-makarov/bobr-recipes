let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let libffi_src =
    recipe.fetch "libffi-src-3.5.2" {
      url = "https://github.com/libffi/libffi/releases/download/v3.5.2/libffi-3.5.2.tar.gz",
      hash = "md5:92af9efad4ba398995abf44835c5d9e9",
    }
  in

  let libffi =
    build.build_autotools {
      name = "libffi-3.5.2",
      sources = [libffi_src],
      script_config = {
        configure_args = [
          "--disable-static",
          "--with-gcc-arch=native",
        ],
      },
    }
  in

  {
    include [
      libffi_src,
      libffi,
    ],
  }
