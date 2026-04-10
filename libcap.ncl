let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let libcap_src =
    recipe.fetch "libcap-src-2.76" {
      url = "https://www.kernel.org/pub/linux/libs/security/linux-privs/libcap2/libcap-2.76.tar.xz",
      hash = "md5:449ade7d620b5c4eeb15a632fbaa4f74",
    }
  in

  let libcap =
    build.build_make {
      name = "libcap-2.76",
      sources = [libcap_src],
      script_config = {
        pre_build = "sed -i '/install -m.*STA/d' libcap/Makefile",
        make_args = [
          "prefix=/usr",
          "lib=lib",
        ],
      },
    }
  in

  {
    include [
      libcap_src,
      libcap,
    ],
  }
