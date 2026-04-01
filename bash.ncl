let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let bash_src_5_3 =
    recipe.fetch "bash-src-5.3" {
      url = [
        "https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz",
        "https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz",
      ],
      hash = "md5:977c8c0c5ae6309191e7768e28ebc951",
    }
  in

  let bash_gen1_5_3 =
    recipe.binary "bash-gen1-5.3" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = [
          "--without-bash-malloc",
          "--disable-readline",
        ],
        post_install = "ln -svf bash \"/out/${out}/usr/bin/sh\"",
      },
    } pkgs.host_image pkgs.buildscript_autotools [bash_src_5_3]
  in

  let bash_5_3 =
    build.build_autotools {
      name = "bash-5.3",
      sources = [bash_src_5_3],
      script_config = {
        configure_args = [
          "--without-bash-malloc",
        ],
        post_install = "ln -svf bash \"/out/${out}/usr/bin/sh\"",
      },
    }
  in

  {
    include [
      bash_src_5_3,
      bash_gen1_5_3,
      bash_5_3,
    ],
  }
