let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let xz_src = {
    name = "xz-src-5.8.1",
    tag = "Source",
    object_hash = "2859a998c1fc494241345f5dae5362f0b2d44087d98edc1fa72f74c294b93902",
    origin = {
      type = "http",
      url = "https://github.com/tukaani-project/xz/releases/download/v5.8.1/xz-5.8.1.tar.xz",
      unpack = true,
    },
    meta = {},
  }
  in

  let xz = {
    name = "xz-5.8.1",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-static",
        "--docdir=/usr/share/doc/xz-5.8.1",
      ],
    },
    inputs = {
      image = pkgs.system_image_2,
      source = xz_src,
    },
  }
  in

  {
    include [
      xz_src,
      xz,
    ],
  }
