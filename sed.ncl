let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let sed_src =
    {
      name = "sed-src-4.9",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-4.9.tar.xz",
      ],
      hash = "md5:6aac9b2dbafcd5b7a67a8a9bcb8036c3",
      },
      inputs = {},
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
    recipe.binary "sed-4.9" {
      script_config = {
        configure_args = ["--disable-nls", "--without-selinux"],
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [sed_src]
  in

  {
    include [
      sed_src,
      sed_gen1,
      sed,
    ],
  }
