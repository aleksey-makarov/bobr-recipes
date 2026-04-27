let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zstd_src = {
    name = "zstd-src-1.5.7",
    tag = "Source",
    object_hash = "21c1e49af79310cf1e8b44549cd3b174d83097a83797bf3c7b97e419fbb44aa0",
    origin = {
      type = "http",
      url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz",
      unpack = true,
    },
    meta = {},
  }
  in

  let zstd = {
    name = "zstd-1.5.7",
    tag = "Makefile",
    config = {
      make_args = [
        "prefix=/usr",
      ],
      post_install = {
        name = "remove_static_library",
        run_as = "root",
        argv = [
          "rm",
          "-fv",
          "@{out}/usr/lib/libzstd.a",
        ],
      },
    },
    inputs = {
      image = pkgs.system_image_2,
      source = zstd_src,
    },
  }
  in

  {
    include [
      zstd_src,
      zstd,
    ],
  }
