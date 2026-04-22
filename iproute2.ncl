let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iproute2_src = {
    name = "iproute2-src-6.16.0",
    tag = "Fetch",
    config = {
      url = "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.16.0.tar.xz",
      hash = "md5:80e1f91bf59d572acc15d5c6eb4f3e7c",
    },
    inputs = {},
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
        cwd = "@{source}",
        argv = [
          "/bin/sh",
          "-ec",
          "install -vDm644 COPYING README* -t \"@{out}/usr/share/doc/iproute2-6.16.0\"",
        ],
      },
    },
    inputs = {
      image = pkgs.system_image,
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
