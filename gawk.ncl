let buildscripts = import "buildscripts/autotools_orig.ncl" in
let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let gawk_src_5_3_2 =
    recipe.fetch "gawk-src-5.3.2" {
      url = [
        "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz",
        "https://mirrors.kernel.org/gnu/gawk/gawk-5.3.2.tar.xz",
      ],
      hash = "md5:b7014650c5f45e5d4837c31209dc0037",
    }
  in

  let gawk_buildscript_source_5_3_2 =
    (buildscripts.autotools {
      pre_configure = "sed -i 's/extras//' Makefile.in",
      configure_args = ["--without-readline"],
    })
  in

  let buildscript_gawk_gen1_5_3_2 =
    recipe.text "buildscript-gawk-gen1-5.3.2" {
      kind = "build-script",
      source = gawk_buildscript_source_5_3_2,
    }
  in

  let gawk_gen1_5_3_2 =
    recipe.binary "gawk-gen1-5.3.2" {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_gawk_gen1_5_3_2 [gawk_src_5_3_2]
  in

  let gawk_5_3_2 =
    build.build_autotools {
      name = "gawk-5.3.2",
      sources = [gawk_src_5_3_2],
      script_config = {
        pre_configure = "sed -i 's/extras//' Makefile.in",
        configure_args = ["--without-readline"],
      },
    }
  in

  {
    include [
      gawk_src_5_3_2,
      gawk_gen1_5_3_2,
      gawk_5_3_2,
    ],
  }
