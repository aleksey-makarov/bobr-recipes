let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gmp_src = {
    name = "gmp-src-6.3.0",
    tag = "Fetch",
    config = {
      url = [
        "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz",
      ],
      hash = "md5:956dc04e864001a9c22429f761f2c283",
    },
    inputs = {},
  }
  in

  let gmp = {
    name = "gmp-6.3.0",
    tag = "Autotools",
    config = {
      pre_configure = {
        name = "patch_configure",
        run_as = "build-user",
        argv = [
          "/bin/sh",
          "-ec",
          "sed -i '/long long t1;/,+1s/()/(...)/' configure",
        ],
      },
      configure_args = [
        "--enable-cxx",
        "--disable-static",
        "--docdir=/usr/share/doc/gmp-6.3.0",
      ],
    },
    inputs = {
      image = pkgs.system_image,
      source = gmp_src,
    },
  }
  in

  {
    include [
      gmp_src,
      gmp,
    ],
  }
