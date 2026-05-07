let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let sed_src = {
    name = "sed-src-4.9",
    tag = "Source",
    object_hash = "51f4169cb5f56f544a72cef9168c3bdd7114a031db13085bb7492140a2a0ed5b",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-4.9.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let sed_gen1 = {
    name = "sed-gen1-4.9",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      image = pkgs.buildpack_deps_image,
      source = sed_src,
    },
  }
  in

  let sed = {
    name = "sed-4.9",
    tag = "Autotools",
    config = {
      configure_args = ["--disable-nls", "--without-selinux"],
    },
    inputs = {
      image = pkgs.system_image_1,
      source = sed_src,
    },
  }
  in

  {
    include [
      sed_src,
      sed_gen1,
      sed,
    ],
  }
