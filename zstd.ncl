let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zstd_src = {
    name = "zstd-src-1.5.7",
    tag = "Source",
    object_hash = "257a6a752fbf3cd7158d29e3babb73d7a9b0ea2e568932b7bf3d6fc7ee273287",
    origin = {
      type = "http",
      url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz",
    },
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
      rootfs = pkgs.system_rootfs_2,
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
