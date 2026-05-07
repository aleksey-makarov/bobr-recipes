let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bash_src = {
    name = "bash-src-5.3",
    tag = "Source",
    object_hash = "cc575a185ee150d8d366912315792fbef3bf61b060bd3b79b3b932385b5d0ba5",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz",
        "https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let bash_gen1 = {
    name = "bash-gen1-5.3",
    tag = "Autotools",
    config = {
      configure_args = [
        "--without-bash-malloc",
        "--disable-readline",
      ],
      post_install = {
        name = "link_sh",
        run_as = "root",
        argv = [
          "ln",
          "-svf",
          "bash",
          "@{out}/usr/bin/sh",
        ],
      },
    },
    inputs = {
      image = pkgs.buildpack_deps_image,
      source = bash_src,
    },
  }
  in

  let bash = {
    name = "bash-5.3",
    tag = "Autotools",
    config = {
      configure_args = [
        "--without-bash-malloc",
      ],
      post_install = {
        name = "link_sh",
        run_as = "root",
        argv = [
          "ln",
          "-svf",
          "bash",
          "@{out}/usr/bin/sh",
        ],
      },
    },
    inputs = {
      image = pkgs.system_image_1,
      source = bash_src,
    },
  }
  in

  {
    include [
      bash_src,
      bash_gen1,
      bash,
    ],
  }
