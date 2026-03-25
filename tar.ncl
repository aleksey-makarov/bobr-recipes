let buildscripts = import "buildscripts/autotools_orig.ncl" in

fun pkgs =>
  let tar_src_1_35 =
    store.fetch "tar-src-1.35" {
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
    store.text "buildscript-tar-gen1-1.35" {
      kind = "build-script",
      source = tar_buildscript_source_1_35,
    }
  in

  let tar_gen1_1_35 =
    store.bind tar_src_1_35 (fun tar_src =>
    store.bind buildscript_tar_gen1_1_35 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "tar-gen1-1.35" {
      kind = "binary-output",
      optimize = "size",
    } image script [tar_src])))
  in

  let tar_1_35 =
    store.bind tar_src_1_35 (fun tar_src =>
    store.bind pkgs.buildscript_autotools (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "tar-1.35" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
        ],
      },
    } image script [tar_src])))
  in

  {
    include [
      tar_src_1_35,
      tar_gen1_1_35,
      tar_1_35,
    ],
  }
