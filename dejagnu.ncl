let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dejagnu_src = {
    name = "dejagnu-src-1.6.3",
    tag = "Fetch",
    config = {
      url = "https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz",
      hash = "md5:68c5208c58236eba447d7d6d1326b821",
    },
    inputs = {},
  }
  in

  let dejagnu_build_image = {
    name = "dejagnu-build-image",
    tag = "Image",
    config = { ref_name | default = "dejagnu-build-image" } & {},
    inputs =
      { base = pkgs.system_image }
      & recipe.numbered_inputs [
        pkgs.tcl,
        pkgs.expect,
        pkgs.texinfo,
      ],
  }
  in

  let buildscript_dejagnu = {
    name = "buildscript-dejagnu",
    tag = "Text",
    config = {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        cd "${MBUILD_SOURCE_DIR}"
        mkdir -pv build
        cd build
        mkdir -p .tmp doc "${MBUILD_INSTALL_DIR}/usr/share/doc/dejagnu-1.6.3"
        export TMPDIR="${TMPDIR:-$PWD/.tmp}"

        ../configure --prefix=/usr
        makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
        makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"$jobs"
        make DESTDIR="${MBUILD_INSTALL_DIR}" install
        rm -f "${MBUILD_INSTALL_DIR}/usr/share/info/dir"
        install -v -m644 doc/dejagnu.html doc/dejagnu.txt "${MBUILD_INSTALL_DIR}/usr/share/doc/dejagnu-1.6.3"
      "%,
    },
    inputs = {},
  }
  in

  let dejagnu = {
    name = "dejagnu-1.6.3",
    tag = "Binary",
    config = {
      steps = [
        recipe.steps.env_step
          "install"
          "root"
          "${build}"
          ["${script}"]
          {
            MBUILD_SOURCE_DIR = "${source}",
            MBUILD_INSTALL_DIR = "${out}",
          },
      ],
      script_config = {},
    },
    inputs = {
      image = dejagnu_build_image,
      script = buildscript_dejagnu,
      source = dejagnu_src,
    },
  }
  in

  {
    include [
      dejagnu_src,
      buildscript_dejagnu,
      dejagnu,
    ],
  }
