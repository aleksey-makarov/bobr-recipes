let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let gmp_src =
    recipe.fetch "gmp-src-6.3.0" {
      url = [
        "https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz",
        "https://mirrors.kernel.org/gnu/gmp/gmp-6.3.0.tar.xz",
      ],
      hash = "md5:956dc04e864001a9c22429f761f2c283",
    }
  in

  let gmp =
    build.build_autotools {
      name = "gmp-6.3.0",
      sources = [gmp_src],
      script_config = {
        pre_configure = "sed -i '/long long t1;/,+1s/()/(...)/' configure",
        configure_args = [
          "--enable-cxx",
          "--disable-static",
          "--docdir=/usr/share/doc/gmp-6.3.0",
        ],
      },
    }
  in

  {
    include [
      gmp_src,
      gmp,
    ],
  }
