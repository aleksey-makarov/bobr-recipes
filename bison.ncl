let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bison_src = {
    name = "bison-src-3.8.2",
    tag = "Source",
    object_hash = "0c50e2d3339a5bbbe95673b168d78e5dc1896b8cfb0bf0e91fa33798bb2c30c6",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-3.8.2.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let bison_gen1 = {
    name = "bison-gen1-3.8.2",
    tag = "Autotools",
    config = {},
    inputs = {
      image = pkgs.buildpack_deps_image,
      source = bison_src,
    },
  }
  in

  let bison = {
    name = "bison-3.8.2",
    tag = "Autotools",
    config = {},
    inputs = {
      image = pkgs.system_image_1,
      source = bison_src,
    },
  }
  in

  {
    include [
      bison_src,
      bison_gen1,
      bison,
    ],
  }
