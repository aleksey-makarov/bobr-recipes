let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let m4_src = {
    name = "m4-src-1.4.20",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.xz",
        "https://mirrors.kernel.org/gnu/m4/m4-1.4.20.tar.xz",
      ],
      hash = "md5:6eb2ebed5b24e74b6e890919331d2132",
    },
    inputs = {},
  }
  in

  let m4_gen1 = {
    name = "m4-gen1-1.4.20",
    tag = "Autotools",
    config = {},
    inputs = {
      image = pkgs.host_image,
      source = m4_src,
    },
  }
  in

  let m4 = {
    name = "m4-1.4.20",
    tag = "Autotools",
    config = {},
    inputs = {
      image = pkgs.system_image_1,
      source = m4_src,
    },
  }
  in

  {
    include [
      m4_src,
      m4_gen1,
      m4,
    ],
  }
