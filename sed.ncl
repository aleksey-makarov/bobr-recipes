let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let sed_src_4_9 =
    store.fetch "sed-src-4.9" {
      url = [
        "https://ftp.gnu.org/gnu/sed/sed-4.9.tar.xz",
        "https://mirrors.kernel.org/gnu/sed/sed-4.9.tar.xz",
      ],
      hash = "md5:6aac9b2dbafcd5b7a67a8a9bcb8036c3",
    }
  in

  let sed_buildscript_source_4_9 =
    (buildscripts.autotools {
      output = "buildscript-sed-gen1-4.9",
      configure_args = ["--disable-nls", "--without-selinux"],
    }).source
  in

  let buildscript_sed_gen1_4_9 =
    store.text "buildscript-sed-gen1-4.9" {
      kind = "build-script",
      source = sed_buildscript_source_4_9,
    }
  in

  let sed_gen1_4_9 =
    store.bind sed_src_4_9 (fun sed_src =>
    store.bind buildscript_sed_gen1_4_9 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "sed-gen1-4.9" {
      kind = "binary-output",
      optimize = "size",
    } image script [sed_src])))
  in

  let buildscript_sed_4_9 =
    store.text "buildscript-sed-4.9" {
      kind = "build-script",
      source = sed_buildscript_source_4_9,
    }
  in

  let sed_4_9 =
    store.bind sed_src_4_9 (fun sed_src =>
    store.bind buildscript_sed_4_9 (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "sed-4.9" {
      kind = "binary-output",
      optimize = "size",
    } image script [sed_src])))
  in

  {
    include [
      sed_src_4_9,
      sed_gen1_4_9,
      sed_4_9,
    ],
  }
