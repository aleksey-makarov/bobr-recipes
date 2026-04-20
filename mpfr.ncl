let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mpfr_src =
    {
      name = "mpfr-src-4.2.2",
      tag = "Fetch",
      config = {
      url = [
        "https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
        "https://mirrors.kernel.org/gnu/mpfr/mpfr-4.2.2.tar.xz",
      ],
      hash = "md5:7c32c39b8b6e3ae85f25156228156061",
      },
      inputs = {},
    }
  in

  let mpfr_build_image =
    recipe.image "mpfr-build-image" {} pkgs.system_image [
      pkgs.gmp,
    ]
  in

  let mpfr =
    recipe.binary "mpfr-4.2.2" {
      script_config = {
        configure_args = [
          "--disable-static",
          "--enable-thread-safe",
          "--docdir=/usr/share/doc/mpfr-4.2.2",
        ],
      },
    } mpfr_build_image pkgs.buildscript_autotools [mpfr_src]
  in

  {
    include [
      mpfr_src,
      mpfr,
    ],
  }
