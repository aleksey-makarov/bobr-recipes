let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grep_src = {
    name = "grep-src-3.12",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grep/grep-3.12.tar.xz",
      ],
      hash = "md5:5d9301ed9d209c4a88c8d3a6fd08b9ac",
    },
    inputs = {},
  }
  in

  let grep_gen1 = {
    name = "grep-gen1-3.12",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      image = pkgs.host_image,
      source = grep_src,
    },
  }
  in

  let grep = {
    name = "grep-3.12",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      image = pkgs.system_image_1,
      source = grep_src,
    },
  }
  in

  {
    include [
      grep_src,
      grep_gen1,
      grep,
    ],
  }
