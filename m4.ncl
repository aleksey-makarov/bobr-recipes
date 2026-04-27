let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let m4_src = {
    name = "m4-src-1.4.20",
    tag = "Source",
    object_hash = "b4411f1e520623d5280b41d7133987e068318ea369b8866f61a0633ae7e58691",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.xz",
        "https://mirrors.kernel.org/gnu/m4/m4-1.4.20.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
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
