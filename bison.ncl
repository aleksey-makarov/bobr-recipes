let buildscripts = import "buildscripts/autotools_orig.ncl" in
let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let bison_src_3_8_2 =
    recipe.fetch "bison-src-3.8.2" {
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-3.8.2.tar.xz",
      ],
      hash = "md5:c28f119f405a2304ff0a7ccdcc629713",
    }
  in

  let bison_buildscript_source_3_8_2 =
    (buildscripts.autotools {
    })
  in

  let buildscript_bison_gen1_3_8_2 =
    recipe.text "buildscript-bison-gen1-3.8.2" {
      kind = "build-script",
      source = bison_buildscript_source_3_8_2,
    }
  in

  let bison_gen1_3_8_2 =
    recipe.binary "bison-gen1-3.8.2" {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_bison_gen1_3_8_2 [bison_src_3_8_2]
  in

  let bison_3_8_2 =
    build.build_autotools {
      name = "bison-3.8.2",
      sources = [bison_src_3_8_2],
      script_config = {},
    }
  in

  {
    include [
      bison_src_3_8_2,
      bison_gen1_3_8_2,
      bison_3_8_2,
    ],
  }
