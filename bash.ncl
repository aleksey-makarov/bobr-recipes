let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bash_src =
    {
      name = "bash-src-5.3",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz",
        "https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz",
      ],
      hash = "md5:977c8c0c5ae6309191e7768e28ebc951",
      },
      inputs = {},
    }
  in

  let bash_gen1 =
    recipe.binary "bash-gen1-5.3" {
      script_config = {
        configure_args = [
          "--without-bash-malloc",
          "--disable-readline",
        ],
        post_install = "ln -svf bash \"${MBUILD_INSTALL_DIR}/usr/bin/sh\"",
      },
    } pkgs.host_image pkgs.buildscript_autotools [bash_src]
  in

  let bash =
    recipe.binary "bash-5.3" {
      script_config = {
        configure_args = [
          "--without-bash-malloc",
        ],
        post_install = "ln -svf bash \"${MBUILD_INSTALL_DIR}/usr/bin/sh\"",
      },
    } pkgs.system_image_1 pkgs.buildscript_autotools [bash_src]
  in

  {
    include [
      bash_src,
      bash_gen1,
      bash,
    ],
  }
