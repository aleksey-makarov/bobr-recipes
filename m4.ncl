let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let m4_src_1_4_20 =
    recipe.fetch "m4-src-1.4.20" {
      url = [
        "https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.xz",
        "https://mirrors.kernel.org/gnu/m4/m4-1.4.20.tar.xz",
      ],
      hash = "md5:6eb2ebed5b24e74b6e890919331d2132",
    }
  in

  let m4_gen1_1_4_20 =
    recipe.binary "m4-gen1-1.4.20" {
      kind = "binary-output",
      optimize = "size",
      script_config = {},
    } pkgs.host_image pkgs.buildscript_autotools [m4_src_1_4_20]
  in

  let m4_1_4_20 =
    build.build_autotools {
      name = "m4-1.4.20",
      sources = [m4_src_1_4_20],
      script_config = {},
    }
  in

  {
    include [
      m4_src_1_4_20,
      m4_gen1_1_4_20,
      m4_1_4_20,
    ],
  }
