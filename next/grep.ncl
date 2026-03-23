let buildscripts = import "buildscripts.ncl" in

fun pkgs =>
  let grep_src_3_12 =
    store.fetch "grep-src-3.12" {
      url = [
        "https://ftp.gnu.org/gnu/grep/grep-3.12.tar.xz",
        "https://mirrors.kernel.org/gnu/grep/grep-3.12.tar.xz",
      ],
      hash = "md5:5d9301ed9d209c4a88c8d3a6fd08b9ac",
    }
  in

  let grep_buildscript_source_3_12 =
    (buildscripts.autotools {
      output = "buildscript-grep-gen1-3.12",
      configure_args = ["--disable-nls", "--disable-perl-regexp"],
    }).source
  in

  let buildscript_grep_gen1_3_12 =
    store.text "buildscript-grep-gen1-3.12" {
      kind = "build-script",
      source = grep_buildscript_source_3_12,
    }
  in

  let grep_gen1_3_12 =
    store.bind grep_src_3_12 (fun grep_src =>
    store.bind buildscript_grep_gen1_3_12 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "grep-gen1-3.12" {
      kind = "binary-output",
      optimize = "size",
    } image script [grep_src])))
  in

  let buildscript_grep_3_12 =
    store.text "buildscript-grep-3.12" {
      kind = "build-script",
      source = grep_buildscript_source_3_12,
    }
  in

  let grep_3_12 =
    store.bind grep_src_3_12 (fun grep_src =>
    store.bind buildscript_grep_3_12 (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "grep-3.12" {
      kind = "binary-output",
      optimize = "size",
    } image script [grep_src])))
  in

  {
    include [
      grep_src_3_12,
      buildscript_grep_gen1_3_12,
      grep_gen1_3_12,
      buildscript_grep_3_12,
      grep_3_12,
    ],
  }
