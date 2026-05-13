let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let findutils_src = {
    name = "findutils-src-4.10.0",
    tag = "Source",
    object_hash = "e684950a928af4b5e9d00ccded2e57d7838124af00810b89a0e51b503f254921",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz",
      ],
    },
    meta = {},
  }
  in

  let findutils_gen1 = {
    name = "findutils-gen1-4.10.0",
    tag = "AutotoolsSandbox",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      rootfs = pkgs.buildpack_deps_rootfs,
      source = findutils_src,
    },
  }
  in

  let findutils = {
    name = "findutils-4.10.0",
    tag = "AutotoolsSandbox",
    config = {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_1,
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
