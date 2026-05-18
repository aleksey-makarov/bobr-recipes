let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iproute2_src = {
    name = "iproute2-src-6.16.0",
    tag = "Source",
    object_hash = "5f574f0c0c90971c342eecf5751cd7cdb61494bef06aea53fd8ebc8f459bef18",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.16.0.tar.xz",
    },
  }
  in

  let iproute2 = {
    name = "iproute2-6.16.0",
    tag = "Makefile",
    config = {
      pre_build = {
        name = "prepare_iproute2_sources",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            sed -i /ARPD/d Makefile
            rm -fv man/man8/arpd.8
          "%,
        ],
      },
      make_args = [
        "NETNS_RUN_DIR=/run/netns",
        "SBINDIR=/usr/sbin",
      ],
      post_install = {
        name = "install_docs",
        run_as = "root",
        cwd = "@{build}/source",
        argv = [
          "/bin/sh",
          "-ec",
          "install -vDm644 COPYING README* -t \"@{out}/usr/share/doc/iproute2-6.16.0\"",
        ],
      },
    },
    inputs = {
      rootfs = pkgs.system_rootfs,
      source = iproute2_src,
    },
  }
  in

  {
    include [
      iproute2_src,
      iproute2,
    ],
  }
