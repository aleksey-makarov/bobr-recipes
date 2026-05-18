let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tar_src = {
    name = "tar-src-1.35",
    tag = "Source",
    object_hash = "ac0a4bf36f64e93e380880d2e48138caa6cf941f6cc460aeb0bdf232022a1b69",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz",
        "https://mirrors.kernel.org/gnu/tar/tar-1.35.tar.xz",
      ],
    },
  }
  in

  let tar_gen1 = {
    name = "tar-gen1-1.35",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
      ],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = tar_src,
    },
  }
  in

  let tar = {
    name = "tar-1.35",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_1,
      source = tar_src,
    },
  }
  in

  {
    include [
      tar_src,
      tar_gen1,
      tar,
    ],
  }
