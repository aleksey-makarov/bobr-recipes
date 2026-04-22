let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let findutils_src = {
    name = "findutils-src-4.10.0",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz",
      ],
      hash = "md5:870cfd71c07d37ebe56f9f4aaf4ad872",
    },
    inputs = {},
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
      image = pkgs.host_image,
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
