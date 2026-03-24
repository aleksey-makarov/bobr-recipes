let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let patch_src_2_8 =
    store.fetch "patch-src-2.8" {
      url = [
        "https://ftp.gnu.org/gnu/patch/patch-2.8.tar.xz",
        "https://mirrors.kernel.org/gnu/patch/patch-2.8.tar.xz",
      ],
      hash = "md5:149327a021d41c8f88d034eab41c039f",
    }
  in

  let patch_buildscript_source_2_8 =
    (buildscripts.autotools {
      configure_args = ["--disable-nls"],
    })
  in

  let buildscript_patch_gen1_2_8 =
    store.text "buildscript-patch-gen1-2.8" {
      kind = "build-script",
      source = patch_buildscript_source_2_8,
    }
  in

  let patch_gen1_2_8 =
    store.bind patch_src_2_8 (fun patch_src =>
    store.bind buildscript_patch_gen1_2_8 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "patch-gen1-2.8" {
      kind = "binary-output",
      optimize = "size",
    } image script [patch_src])))
  in

  let buildscript_patch_2_8 =
    buildscript_patch_gen1_2_8
  in

  let patch_2_8 =
    store.bind patch_src_2_8 (fun patch_src =>
    store.bind buildscript_patch_2_8 (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "patch-2.8" {
      kind = "binary-output",
      optimize = "size",
    } image script [patch_src])))
  in

  {
    include [
      patch_src_2_8,
      patch_gen1_2_8,
      patch_2_8,
    ],
  }
