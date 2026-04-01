let buildscripts = import "buildscripts/autotools_orig.ncl" in
let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let sed_src_4_9 =
    recipe.fetch "sed-src-4.9" {
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-4.9.tar.xz",
      ],
      hash = "md5:6aac9b2dbafcd5b7a67a8a9bcb8036c3",
    }
  in

  let sed_buildscript_source_4_9 =
    (buildscripts.autotools {
      configure_args = ["--disable-nls", "--without-selinux"],
    })
  in

  let buildscript_sed_gen1_4_9 =
    recipe.text "buildscript-sed-gen1-4.9" {
      kind = "build-script",
      source = sed_buildscript_source_4_9,
    }
  in

  let sed_gen1_4_9 =
    recipe.binary "sed-gen1-4.9" {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_sed_gen1_4_9 [sed_src_4_9]
  in

  let sed_4_9 =
    build.build_autotools {
      name = "sed-4.9",
      sources = [sed_src_4_9],
      script_config = {
        configure_args = ["--disable-nls", "--without-selinux"],
      },
    }
  in

  {
    include [
      sed_src_4_9,
      sed_gen1_4_9,
      sed_4_9,
    ],
  }
