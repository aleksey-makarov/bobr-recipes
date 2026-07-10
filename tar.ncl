let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tar_src = {
    name = "tar-src-1.35",
    tag = "Source",
    object_hash = "4d62ff37342ec7aed748535323930c7cf94acf71c3591882b26a7ea50f3edc16",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz",
        "https://mirrors.kernel.org/gnu/tar/tar-1.35.tar.xz",
      ],
    },
  }
  in

  let tar_gen1 = {
    name = "tar-gen1-1.35",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
      ],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = tar_src,
    },
  }
  in

  let tar = {
    name = "tar-1.35",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
      ],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = tar_src,
    },
  }
  in

  {
    include [
      tar_gen1,
      tar,
    ],
  }
