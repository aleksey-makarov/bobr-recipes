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

  let tar_gen1_1_35 =
    recipe.binary "tar-gen1-1.35" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
        ],
      },
    } pkgs.host_image pkgs.buildscript_autotools [tar_src_1_35]
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
