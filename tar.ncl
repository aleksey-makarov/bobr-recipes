let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tar_src = {
    name = "tar-src-1.35",
    tag = "Source",
    object_hash = "687da4655985992a12ec70eda7c7cacbe979f04618d93f9a599d8631ee57a905",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz",
        "https://mirrors.kernel.org/gnu/tar/tar-1.35.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let tar_gen1 = {
    name = "tar-gen1-1.35",
    tag = "AutotoolsSandbox",
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
