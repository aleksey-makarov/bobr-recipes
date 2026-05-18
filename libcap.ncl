let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libcap_src = {
    name = "libcap-src-2.76",
    tag = "Source",
    object_hash = "0b4ab42297fcc500b2f6bf7e84541f5efbe5bb2160343733bd153cb8ecbca4c5",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.76.tar.xz",
    },
  }
  in

  let libcap = {
    name = "libcap-2.76",
    tag = "Makefile",
    config = {
      pre_build = {
        name = "drop_static_install_rule",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i '/install -m.*STA/d' libcap/Makefile",
        ],
      },
      make_args = [
        "prefix=/usr",
        "lib=lib",
      ],
    },
    inputs = {
      rootfs = pkgs.system_rootfs_2,
      source = libcap_src,
    },
  }
  in

  {
    include [
      libcap_src,
      libcap,
    ],
  }
