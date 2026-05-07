let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let findutils_src = {
    name = "findutils-src-4.10.0",
    tag = "Source",
    object_hash = "26cabe4ff20bd3095dee4f8791db3975e21b1da47a8411de3f11698d4b2feb96",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz",
      ],
      unpack = true,
    },
    meta = {},
  }
  in

  let findutils_gen1 = {
    name = "findutils-gen1-4.10.0",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      image = pkgs.buildpack_deps_image,
      source = findutils_src,
    },
  }
  in

  let findutils = {
    name = "findutils-4.10.0",
    tag = "Autotools",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      image = pkgs.system_image_1,
      source = findutils_src,
    },
  }
  in

  {
    include [
      findutils_src,
      findutils_gen1,
      findutils,
    ],
  }
