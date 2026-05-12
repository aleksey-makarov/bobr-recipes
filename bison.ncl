let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bison_src = {
    name = "bison-src-3.8.2",
    tag = "Source",
    object_hash = "9627c7db5136d53d1935cac9744d70130f82d98f40f117a7fd45a66a3d9858eb",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-3.8.2.tar.xz",
      ],
    },
    meta = {},
  }
  in

  let bison_gen1 = {
    name = "bison-gen1-3.8.2",
    tag = "AutotoolsSandbox",
    config = {},
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
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
