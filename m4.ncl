let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let m4_src_1_4_20 =
    store.fetch "m4-src-1.4.20" {
      url = [
        "https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.xz",
        "https://mirrors.kernel.org/gnu/m4/m4-1.4.20.tar.xz",
      ],
      hash = "md5:6eb2ebed5b24e74b6e890919331d2132",
    }
  in

  let m4_buildscript_source_1_4_20 =
    (buildscripts.autotools {
    })
  in

  let buildscript_m4_gen1_1_4_20 =
    store.text "buildscript-m4-gen1-1.4.20" {
      kind = "build-script",
      source = m4_buildscript_source_1_4_20,
    }
  in

  let m4_gen1_1_4_20 =
    store.bind m4_src_1_4_20 (fun m4_src =>
    store.bind buildscript_m4_gen1_1_4_20 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "m4-gen1-1.4.20" {
      kind = "binary-output",
      optimize = "size",
    } image script [m4_src])))
  in

  let buildscript_m4_1_4_20 =
    buildscript_m4_gen1_1_4_20
  in

  let m4_1_4_20 =
    store.bind m4_src_1_4_20 (fun m4_src =>
    store.bind buildscript_m4_1_4_20 (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "m4-1.4.20" {
      kind = "binary-output",
      optimize = "size",
    } image script [m4_src])))
  in

  {
    include [
      m4_src_1_4_20,
      m4_gen1_1_4_20,
      m4_1_4_20,
    ],
  }
