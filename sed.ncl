let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let sed_src =
    recipe.fetch "sed-src-4.9" {
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-4.9.tar.xz",
      ],
      hash = "md5:6aac9b2dbafcd5b7a67a8a9bcb8036c3",
    }
  in

  let sed_gen1 =
    recipe.binary "sed-gen1-4.9" {
      script_config = {
        configure_args = ["--disable-nls", "--without-selinux"],
      },
    } pkgs.host_image pkgs.buildscript_autotools [sed_src]
  in

  let sed =
    build.build_autotools {
      name = "sed-4.9",
      sources = [sed_src],
      script_config = {
        configure_args = ["--disable-nls", "--without-selinux"],
      },
    }
  in

  {
    include [
      sed_src,
      sed_gen1,
      sed,
    ],
  }
