let buildscripts = import "buildscripts/autotools_orig.ncl" in

fun pkgs =>
  let findutils_src_4_10_0 =
    store.fetch "findutils-src-4.10.0" {
      url = [
        "https://ftp.gnu.org/gnu/findutils/findutils-4.10.0.tar.xz",
        "https://mirrors.kernel.org/gnu/findutils/findutils-4.10.0.tar.xz",
      ],
      hash = "md5:870cfd71c07d37ebe56f9f4aaf4ad872",
    }
  in

  let findutils_buildscript_source_4_10_0 =
    (buildscripts.autotools {
      configure_args = [
        "--disable-nls",
        "--without-selinux",
        "--localstatedir=/var/lib/locate",
      ],
    })
  in

  let buildscript_findutils_gen1_4_10_0 =
    store.text "buildscript-findutils-gen1-4.10.0" {
      kind = "build-script",
      source = findutils_buildscript_source_4_10_0,
    }
  in

  let findutils_gen1_4_10_0 =
    store.bind findutils_src_4_10_0 (fun findutils_src =>
    store.bind buildscript_findutils_gen1_4_10_0 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "findutils-gen1-4.10.0" {
      kind = "binary-output",
      optimize = "size",
    } image script [findutils_src])))
  in

  let findutils_4_10_0 =
    store.bind findutils_src_4_10_0 (fun findutils_src =>
    store.bind pkgs.buildscript_autotools (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "findutils-4.10.0" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        configure_args = [
          "--disable-nls",
          "--without-selinux",
          "--localstatedir=/var/lib/locate",
        ],
      },
    } image script [findutils_src])))
  in

  {
    include [
      findutils_src_4_10_0,
      findutils_gen1_4_10_0,
      findutils_4_10_0,
    ],
  }
