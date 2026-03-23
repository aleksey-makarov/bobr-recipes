let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let gzip_src_1_14 =
    store.fetch "gzip-src-1.14" {
      url = [
        "https://ftp.gnu.org/gnu/gzip/gzip-1.14.tar.xz",
        "https://mirrors.kernel.org/gnu/gzip/gzip-1.14.tar.xz",
      ],
      hash = "md5:4bf5a10f287501ee8e8ebe00ef62b2c2",
    }
  in

  let gzip_buildscript_source_1_14 =
    (buildscripts.autotools {
      output = "buildscript-gzip-gen1-1.14",
      configure_args = ["--disable-nls"],
    })
  in

  let buildscript_gzip_gen1_1_14 =
    store.text "buildscript-gzip-gen1-1.14" {
      kind = "build-script",
      source = gzip_buildscript_source_1_14,
    }
  in

  let gzip_gen1_1_14 =
    store.bind gzip_src_1_14 (fun gzip_src =>
    store.bind buildscript_gzip_gen1_1_14 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "gzip-gen1-1.14" {
      kind = "binary-output",
      optimize = "size",
    } image script [gzip_src])))
  in

  let buildscript_gzip_1_14 =
    store.text "buildscript-gzip-1.14" {
      kind = "build-script",
      source = gzip_buildscript_source_1_14,
    }
  in

  let gzip_1_14 =
    store.bind gzip_src_1_14 (fun gzip_src =>
    store.bind buildscript_gzip_1_14 (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "gzip-1.14" {
      kind = "binary-output",
      optimize = "size",
    } image script [gzip_src])))
  in

  {
    include [
      gzip_src_1_14,
      gzip_gen1_1_14,
      gzip_1_14,
    ],
  }
