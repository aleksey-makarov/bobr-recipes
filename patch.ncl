let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let patch_src = {
    name = "patch-src-2.8",
    tag = "Source",
    object_hash = "c4fa1fcb69e29607159a469efebda0757341028d4f68e70d3540110425788e9a",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz",
        "https://mirrors.kernel.org/gnu/patch/patch-2.8.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let patch_gen1 = {
    name = "patch-gen1-2.8",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls"],
    },
    inputs = {
      image = pkgs.buildpack_deps_image,
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
