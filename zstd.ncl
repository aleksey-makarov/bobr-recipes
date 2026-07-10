let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let zstd_src = {
    name = "zstd-src-1.5.7",
    tag = "Source",
    object_hash = "eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3",
    origin = {
      tag = "Http",
      url = "https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz",
    },
  }
  in

  let zstd = {
    name = "zstd-1.5.7",
    tag = "MakefileRootfs",
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
      _rootfs = pkgs.system_rootfs_2,
      source = zstd_src,
    },
  }
  in

  {
    include [
      zstd,
    ],
  }
