let buildscripts = import "buildscripts/autotools_orig.ncl" in
let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let tar_src_1_35 =
    recipe.fetch "tar-src-1.35" {
      url = [
        "https://ftp.gnu.org/gnu/tar/tar-1.35.tar.xz",
        "https://mirrors.kernel.org/gnu/tar/tar-1.35.tar.xz",
      ],
      hash = "md5:a2d8042658cfd8ea939e6d911eaf4152",
    }
  in

  let tar_buildscript_source_1_35 =
    (buildscripts.autotools {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
      ],
    })
  in

  let buildscript_tar_gen1_1_35 =
    recipe.text "buildscript-tar-gen1-1.35" {
      kind = "build-script",
      source = tar_buildscript_source_1_35,
    }
  in

  let tar_gen1_1_35 =
    recipe.binary "tar-gen1-1.35" {
      kind = "binary-output",
      optimize = "size",
    } pkgs.host_image buildscript_tar_gen1_1_35 [tar_src_1_35]
  in

  let tar_1_35 =
    build.build_autotools {
      name = "tar-1.35",
      sources = [tar_src_1_35],
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
        ],
      },
    }
  in

  {
    include [
      tar_src_1_35,
      tar_gen1_1_35,
      tar_1_35,
    ],
  }
