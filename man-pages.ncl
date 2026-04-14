let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_pages_src =
    recipe.fetch "man-pages-src-6.15" {
      url = "https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.15.tar.xz",
      hash = "md5:16f68d70139dd2bbcae4102be4705753",
    }
  in

  let buildscript_man_pages =
    recipe.text "buildscript-man-pages" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"
        mkdir -p "/out/${out}"
        rm -fv man3/crypt*
        rm -fv man3/getspnam.3 man3/getspent.3 man3/lckpwdf.3
        rm -fv man5/passwd.5
        make -R GIT=false prefix=/usr DESTDIR="/out/${out}" install
      "%,
    }
  in

  let man_pages =
    recipe.binary "man-pages-6.15" {
      script_config = {},
    } pkgs.system_image buildscript_man_pages [man_pages_src]
  in

  {
    include [
      man_pages_src,
      buildscript_man_pages,
      man_pages,
    ],
  }
