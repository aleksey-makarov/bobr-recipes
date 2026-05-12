let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let patch_src = {
    name = "patch-src-2.8",
    tag = "Source",
    object_hash = "68437bdee29f8ff21172329eddfc21165cf931c41261faaaba78761dec10cda9",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz",
        "https://mirrors.kernel.org/gnu/patch/patch-2.8.tar.xz",
      ],
    },
    meta = {},
  }
  in

  let patch_gen1 = {
    name = "patch-gen1-2.8",
    tag = "AutotoolsSandbox",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = patch_src,
    },
  }
  in

  let patch = {
    name = "patch-2.8",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      image = pkgs.system_image_1,
      source = patch_src,
    },
  }
  in

  {
    include [
      patch_src,
      patch_gen1,
      patch,
    ],
  }
