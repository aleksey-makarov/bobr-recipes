let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tar_src = {
    name = "tar-src-1.35",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz",
        "https://mirrors.kernel.org/gnu/tar/tar-1.35.tar.xz",
      ],
      hash = "md5:a2d8042658cfd8ea939e6d911eaf4152",
    },
    inputs = {},
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
      image = pkgs.host_image,
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
      image = pkgs.system_image_1,
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
