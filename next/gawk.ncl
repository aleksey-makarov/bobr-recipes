let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let gawk_src_5_3_2 =
    store.fetch "gawk-src-5.3.2" {
      url = [
        "https://ftp.gnu.org/gnu/gawk/gawk-5.3.2.tar.xz",
        "https://mirrors.kernel.org/gnu/gawk/gawk-5.3.2.tar.xz",
      ],
      hash = "md5:b7014650c5f45e5d4837c31209dc0037",
    }
  in

  let buildscript_gawk_temp_5_3_2 =
    store.text "buildscript-gawk-temp-5.3.2" {
      kind = "build-script",
      source =
        (buildscripts.autotools {
          output = "buildscript-gawk-temp-5.3.2",
          pre_configure = "sed -i 's/extras//' Makefile.in",
        }).source,
    }
  in

  let gawk_temp_5_3_2 =
    store.bind gawk_src_5_3_2 (fun gawk_src =>
    store.bind buildscript_gawk_temp_5_3_2 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "gawk-temp-5.3.2" {
      kind = "binary-output",
      optimize = "size",
    } image script [gawk_src])))
  in

  {
    include [
      gawk_src_5_3_2,
      buildscript_gawk_temp_5_3_2,
      gawk_temp_5_3_2,
    ],
  }
