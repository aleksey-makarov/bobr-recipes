let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let bison_src_3_8_2 =
    store.fetch "bison-src-3.8.2" {
      url = [
        "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz",
        "https://mirrors.kernel.org/gnu/bison/bison-3.8.2.tar.xz",
      ],
      hash = "md5:c28f119f405a2304ff0a7ccdcc629713",
    }
  in

  let buildscript_bison_gen1_3_8_2 =
    store.text "buildscript-bison-gen1-3.8.2" {
      kind = "build-script",
      source =
        (buildscripts.autotools {
          output = "buildscript-bison-gen1-3.8.2",
        }).source,
    }
  in

  let bison_gen1_3_8_2 =
    store.bind bison_src_3_8_2 (fun bison_src =>
    store.bind buildscript_bison_gen1_3_8_2 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "bison-gen1-3.8.2" {
      kind = "binary-output",
      optimize = "size",
    } image script [bison_src])))
  in

  {
    include [
      bison_src_3_8_2,
      buildscript_bison_gen1_3_8_2,
      bison_gen1_3_8_2,
    ],
  }
