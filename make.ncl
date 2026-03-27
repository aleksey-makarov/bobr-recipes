let buildscripts = import "buildscripts/autotools_orig.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

  let make_src_4_4_1 =
    store.fetch "make-src-4.4.1" {
      url = [
        "https://ftp.gnu.org/gnu/make/make-4.4.1.tar.gz",
        "https://mirrors.kernel.org/gnu/make/make-4.4.1.tar.gz",
      ],
      hash = "md5:c8469a3713cbbe04d955d4ae4be23eeb",
    }
  in

  let make_buildscript_source_4_4_1 =
    (buildscripts.autotools {
      configure_args = ["--disable-nls"],
    })
  in

  let buildscript_make_gen1_4_4_1 =
    store.text "buildscript-make-gen1-4.4.1" {
      kind = "build-script",
      source = make_buildscript_source_4_4_1,
    }
  in

  let make_gen1_4_4_1 =
    store.bind make_src_4_4_1 (fun make_src =>
    store.bind buildscript_make_gen1_4_4_1 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "make-gen1-4.4.1" {
      kind = "binary-output",
      optimize = "size",
    } image script [make_src])))
  in

  let make_4_4_1 =
    build.build_autotools {
      name = "make-4.4.1",
      sources = [make_src_4_4_1],
      script_config = {
        configure_args = ["--disable-nls"],
      },
    }
  in

  {
    include [
      make_src_4_4_1,
      make_gen1_4_4_1,
      make_4_4_1,
    ],
  }
