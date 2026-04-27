let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let gmp_src = {
    name = "gmp-src-6.3.0",
    tag = "Source",
    object_hash = "6296dabb91962e057b9dfe2de2ebd7fea07b3b4f02381e37544cef0ffa36a3eb",
    origin = {
      type = "http",
      url = [
        "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz",
      ],
      unpack = true,
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
