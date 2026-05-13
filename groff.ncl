let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let groff_src = {
    name = "groff-src-1.23.0",
    tag = "Source",
    object_hash = "0b2057b59f7cde3b8282b3133c709ba380d19fd417fd55c6f87b80cdafcc3d13",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/groff/groff-1.23.0.tar.gz",
        "https://mirrors.kernel.org/gnu/groff/groff-1.23.0.tar.gz",
      ],
    },
    meta = {},
  }
  in

  let groff = {
    name = "groff-1.23.0",
    tag = "AutotoolsSandbox",
    config = {
      env = {
        PAGE = "A4",
      },
    },
    inputs = {
      rootfs = pkgs.system_rootfs,
      source = groff_src,
    },
  }
  in

  {
    include [
      groff_src,
      groff,
    ],
  }
