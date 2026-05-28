let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let lz4_src = {
    name = "lz4-src-1.10.0",
    tag = "Source",
    object_hash = "20ec3984ab02967635ef89fbf957f4d9c463a4093ccc0ab5973aecb3cdc3d709",
    origin = {
      tag = "Http",
      url = "https://github.com/lz4/lz4/releases/download/v1.10.0/lz4-1.10.0.tar.gz",
    },
  }
  in

  let lz4 = {
    name = "lz4-1.10.0",
    tag = "MakefileRootfs",
    config = {
      make_args = [
        "BUILD_STATIC=no",
        "PREFIX=/usr",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_2,
      source = lz4_src,
    },
  }
  in

  {
    include [
      lz4_src,
      lz4,
    ],
  }
