let buildscripts = import "buildscripts/autotools_orig.ncl" in

fun pkgs =>
  let diffutils_src_3_12 =
    store.fetch "diffutils-src-3.12" {
      url = [
        "https://ftp.gnu.org/gnu/diffutils/diffutils-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/diffutils/diffutils-3.12.tar.xz",
      ],
      hash = "md5:d1b18b20868fb561f77861cd90b05de4",
    }
  in

  let diffutils_buildscript_source_3_12 =
    (buildscripts.autotools {
      configure_args = ["--disable-nls"],
      env = { gl_cv_func_strcasecmp_works = "y" },
    })
  in

  let buildscript_diffutils_gen1_3_12 =
    store.text "buildscript-diffutils-gen1-3.12" {
      kind = "build-script",
      source = diffutils_buildscript_source_3_12,
    }
  in

  let diffutils_gen1_3_12 =
    store.bind diffutils_src_3_12 (fun diffutils_src =>
    store.bind buildscript_diffutils_gen1_3_12 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "diffutils-gen1-3.12" {
      kind = "binary-output",
      optimize = "size",
    } image script [diffutils_src])))
  in

  let buildscript_diffutils_3_12 =
    buildscript_diffutils_gen1_3_12
  in

  let diffutils_3_12 =
    store.bind diffutils_src_3_12 (fun diffutils_src =>
    store.bind buildscript_diffutils_3_12 (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "diffutils-3.12" {
      kind = "binary-output",
      optimize = "size",
    } image script [diffutils_src])))
  in

  {
    include [
      diffutils_src_3_12,
      diffutils_gen1_3_12,
      diffutils_3_12,
    ],
  }
