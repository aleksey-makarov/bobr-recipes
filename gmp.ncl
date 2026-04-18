let recipe = import "recipe-lib.ncl" in

fun pkgs =>
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
    let script_config = {
        pre_configure = "sed -i '/long long t1;/,+1s/()/(...)/' configure",
        configure_args = [
          "--enable-cxx",
          "--disable-static",
          "--docdir=/usr/share/doc/gmp-6.3.0",
        ],
      }
    in
    recipe.binary "gmp-6.3.0" {
      include script_config,
    } pkgs.system_image pkgs.buildscript_autotools [gmp_src]
  in

  {
    include [
      gmp_src,
      gmp,
    ],
  }
