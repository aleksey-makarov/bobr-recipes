let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let iproute2_src =
    recipe.fetch "iproute2-src-6.16.0" {
      url = "https://www.kernel.org/pub/linux/utils/net/iproute2/iproute2-6.16.0.tar.xz",
      hash = "md5:80e1f91bf59d572acc15d5c6eb4f3e7c",
    }
  in

  let iproute2 =
    let script_config = {
        pre_build = m%"
          sed -i /ARPD/d Makefile
          rm -fv man/man8/arpd.8
        "%,
        make_args = [
          "NETNS_RUN_DIR=/run/netns",
          "SBINDIR=/usr/sbin",
        ],
        post_install = m%"
          install -vDm644 COPYING README* -t "${MBUILD_INSTALL_DIR}/usr/share/doc/iproute2-6.16.0"
        "%,
      }
    in
    recipe.binary "iproute2-6.16.0" {
      include script_config,
    } pkgs.system_image pkgs.buildscript_gnu_make [iproute2_src]
  in

  {
    include [
      iproute2_src,
      iproute2,
    ],
  }
