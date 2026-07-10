let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let patch_src = {
    name = "patch-src-2.8",
    tag = "Source",
    object_hash = "f87cee69eec2b4fcbf60a396b030ad6aa3415f192aa5f7ee84cad5e11f7f5ae3",
    origin = {
      tag = "Http",
      url = [
        "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz",
        "https://mirrors.kernel.org/gnu/patch/patch-2.8.tar.xz",
      ],
    },
  }
  in

  let patch_gen1 = {
    name = "patch-gen1-2.8",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.buildpack_deps_rootfs,
      source = patch_src,
    },
  }
  in

  let patch = {
    name = "patch-2.8",
    tag = "AutotoolsRootfs",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = patch_src,
    },
  }
  in

  {
    include [
      patch_gen1,
      patch,
    ],
  }
