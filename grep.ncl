let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grep_src = {
    name = "grep-src-3.12",
    tag = "Source",
    object_hash = "c6c60e306b7865d331607e6f0317afaf4e0d1721ca4b2661f62a8bf5c08ace88",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grep/grep-3.12.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
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
