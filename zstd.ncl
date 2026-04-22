let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zstd_src = {
    name = "zstd-src-1.5.7",
    tag = "Fetch",
    config = {
      url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz",
      hash = "md5:780fc1896922b1bc52a4e90980cdda48",
    },
    inputs = {},
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
          "${out}/usr/lib/libzstd.a",
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
