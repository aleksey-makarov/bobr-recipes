let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let grep_src = {
    name = "grep-src-3.12",
    tag = "Source",
    object_hash = "1bca0554f8ff216fab035954dfac3218ae1edaa533a29680ceb675404ede5b93",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grep/grep-3.12.tar.xz",
      ],
    },
    meta = {},
  }
  in

  let grep_gen1 = {
    name = "grep-gen1-3.12",
    tag = "AutotoolsSandbox",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = grep_src,
    },
  }
  in

  let grep = {
    name = "grep-3.12",
    tag = "AutotoolsSandbox",
    config = {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_1,
      source = grep_src,
    },
  }
  in

  {
    include [
      grep_src,
      grep_gen1,
      grep,
    ],
  }
