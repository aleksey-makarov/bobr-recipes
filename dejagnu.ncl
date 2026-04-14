let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let dejagnu_src =
    recipe.fetch "dejagnu-src-1.6.3" {
      url = "https://ftp.gnu.org/gnu/dejagnu/dejagnu-1.6.3.tar.gz",
      hash = "md5:68c5208c58236eba447d7d6d1326b821",
    }
  in

  let dejagnu_build_image =
    recipe.image "dejagnu-build-image" {} pkgs.system_image [
      pkgs.tcl,
      pkgs.expect,
      pkgs.texinfo,
    ]
  in

  let buildscript_dejagnu =
    recipe.text "buildscript-dejagnu" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"
        mkdir -pv build
        cd build
        mkdir -p .tmp doc "/out/${out}/usr/share/doc/dejagnu-1.6.3"
        export TMPDIR="${TMPDIR:-$PWD/.tmp}"

        ../configure --prefix=/usr
        makeinfo --html --no-split -o doc/dejagnu.html ../doc/dejagnu.texi
        makeinfo --plaintext -o doc/dejagnu.txt ../doc/dejagnu.texi

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"$jobs"
        make DESTDIR="/out/${out}" install
        rm -f "/out/${out}/usr/share/info/dir"
        install -v -m644 doc/dejagnu.html doc/dejagnu.txt "/out/${out}/usr/share/doc/dejagnu-1.6.3"
      "%,
    }
  in

  let dejagnu =
    recipe.binary "dejagnu-1.6.3" {
      script_config = {},
    } dejagnu_build_image buildscript_dejagnu [dejagnu_src]
  in

  {
    include [
      dejagnu_src,
      buildscript_dejagnu,
      dejagnu,
    ],
  }
