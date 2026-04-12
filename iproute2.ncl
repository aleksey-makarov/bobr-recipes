let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let iproute2_src =
    recipe.fetch "iproute2-src-6.16.0" {
      url = "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.16.0.tar.xz",
      hash = "md5:80e1f91bf59d572acc15d5c6eb4f3e7c",
    }
  in

  let iproute2 =
    build.build_make {
      name = "iproute2-6.16.0",
      sources = [iproute2_src],
      script_config = {
        pre_build = m%"
          sed -i /ARPD/d Makefile
          rm -fv man/man8/arpd.8
        "%,
        make_args = [
          "NETNS_RUN_DIR=/run/netns",
          "SBINDIR=/usr/sbin",
        ],
        post_install = m%"
          install -vDm644 COPYING README* -t "/out/${out}/usr/share/doc/iproute2-6.16.0"
        "%,
      },
    }
  in

  {
    include [
      iproute2_src,
      iproute2,
    ],
  }
