let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gmp_src = {
    name = "gmp-src-6.3.0",
    tag = "Source",
    object_hash = "e86ea25598752f10e3e24ee9480f4043bf5a207e900a2c49a952450f620b7d51",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz",
      ],
    },
    meta = {},
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
      rootfs = pkgs.system_rootfs,
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
