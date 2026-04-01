let buildscripts = import "buildscripts/autotools_orig.ncl" in
let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let grep_src_3_12 =
    recipe.fetch "grep-src-3.12" {
      url = [
        "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grep/grep-3.12.tar.xz",
      ],
      hash = "md5:5d9301ed9d209c4a88c8d3a6fd08b9ac",
    }
  in

  let grep_buildscript_source_3_12 =
    (buildscripts.autotools {
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    })
  in

  let buildscript_grep_gen1_3_12 =
    recipe.text "buildscript-grep-gen1-3.12" {
      kind = "build-script",
      source = grep_buildscript_source_3_12,
    }
  in

  let grep_gen1_3_12 =
    recipe.binary "grep-gen1-3.12" {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_grep_gen1_3_12 [grep_src_3_12]
  in

  let grep_3_12 =
    build.build_autotools {
      name = "grep-3.12",
      sources = [grep_src_3_12],
      script_config = {
        configure_args = ["--disable-nls", "--disable-perl-regexp"],
      },
    }
  in

  {
    include [
      grep_src_3_12,
      grep_gen1_3_12,
      grep_3_12,
    ],
  }
