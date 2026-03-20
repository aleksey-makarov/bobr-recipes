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

  let buildscript_m4_temp_1_4_20 =
    store.text "buildscript-m4-temp-1.4.20" {
      kind = "build-script",
      source =
        (buildscripts.autotools {
          output = "buildscript-m4-temp-1.4.20",
          prepend_path = ["/tools/bin"],
          configure_args = [
            "--host=x86_64-lfs-linux-gnu",
            "--build=x86_64-pc-linux-gnu",
          ],
        }).source,
    }
  in

  let m4_temp_1_4_20 =
    store.bind m4_src_1_4_20 (fun m4_src =>
    store.bind buildscript_m4_temp_1_4_20 (fun script =>
    store.bind pkgs.gcc_temp_build_image (fun image =>
    store.binary "m4-temp-1.4.20" {
      kind = "binary-output",
      optimize = "size",
    } image script [m4_src])))
  in

  {
    include [
      m4_src_1_4_20,
      buildscript_m4_temp_1_4_20,
      m4_temp_1_4_20,
    ],
  }
