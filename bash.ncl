let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bash_src = {
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
          "${out}/usr/bin/sh",
        ],
      },
    },
    inputs = {
      image = pkgs.host_image,
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
          "${out}/usr/bin/sh",
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
