let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let libcap_src = {
    name = "libcap-src-2.76",
    tag = "Source",
    object_hash = "4408f342e49af7bbd7156d75ee6f1c2940beca650122b8300c456f6d51a32259",
    origin = {
      type = "http",
      url = "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.76.tar.xz",
      unpack = true,
    },
    meta = {},
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
      image = pkgs.system_image_2,
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
