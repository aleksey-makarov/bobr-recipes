let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let man_pages_src =
    {
      name = "man-pages-src-6.15",
      tag = "Fetch",
      config = {
      url = "https://www.kernel.org/pub/linux/docs/man-pages/man-pages-6.15.tar.xz",
      hash = "md5:16f68d70139dd2bbcae4102be4705753",
      },
      inputs = {},
    }
  in

  let buildscript_man_pages =
    {
      name = "buildscript-man-pages",
      tag = "Text",
      config = {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        cd "${MBUILD_SOURCE_DIR}"
        mkdir -p "${MBUILD_INSTALL_DIR}"
        rm -fv man3/crypt*
        rm -fv man3/getspnam.3 man3/getspent.3 man3/lckpwdf.3
        rm -fv man5/passwd.5
        make -R GIT=false prefix=/usr DESTDIR="${MBUILD_INSTALL_DIR}" install
      "%,
      },
      inputs = {},
    }
  in

  let man_pages =
    recipe.binary "man-pages-6.15" {
      steps = [
        recipe.steps.step "install" "root" "${build_dir}" ["${script}"],
      ],
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
