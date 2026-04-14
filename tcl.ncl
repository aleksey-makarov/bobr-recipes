let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tcl_src =
    recipe.fetch "tcl-src-8.6.16" {
      url = [
        "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.16/tcl8.6.16-src.tar.gz",
        "https://sourceforge.net/projects/tcl/files/Tcl/8.6.16/tcl8.6.16-src.tar.gz/download",
      ],
      hash = "md5:eaef5d0a27239fb840f04af8ec608242",
    }
  in

  let buildscript_tcl =
    recipe.text "buildscript-tcl" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
        src_root="/in/${src}"

        cd "${src_root}/unix"
        mkdir -p .tmp
        export TMPDIR="${TMPDIR:-$PWD/.tmp}"

        ./configure --prefix=/usr --mandir=/usr/share/man --disable-rpath

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"$jobs"

        sed -e "s|${src_root}/unix|/usr/lib|" \
            -e "s|${src_root}|/usr/include|" \
            -i tclConfig.sh

        sed -e "s|${src_root}/unix/pkgs/tdbc1.1.10|/usr/lib/tdbc1.1.10|" \
            -e "s|${src_root}/pkgs/tdbc1.1.10/generic|/usr/include|" \
            -e "s|${src_root}/pkgs/tdbc1.1.10/library|/usr/lib/tcl8.6|" \
            -e "s|${src_root}/pkgs/tdbc1.1.10|/usr/include|" \
            -i pkgs/tdbc1.1.10/tdbcConfig.sh

        sed -e "s|${src_root}/unix/pkgs/itcl4.3.2|/usr/lib/itcl4.3.2|" \
            -e "s|${src_root}/pkgs/itcl4.3.2/generic|/usr/include|" \
            -e "s|${src_root}/pkgs/itcl4.3.2|/usr/include|" \
            -i pkgs/itcl4.3.2/itclConfig.sh

        mkdir -p "/out/${out}"
        make INSTALL_ROOT="/out/${out}" install
        chmod 644 "/out/${out}/usr/lib/libtclstub8.6.a"
        chmod u+w "/out/${out}/usr/lib/libtcl8.6.so"
        make INSTALL_ROOT="/out/${out}" install-private-headers
        ln -sfv tclsh8.6 "/out/${out}/usr/bin/tclsh"
        mv "/out/${out}/usr/share/man/man3/Thread.3" "/out/${out}/usr/share/man/man3/Tcl_Thread.3"
      "%,
    }
  in

  let tcl =
    recipe.binary "tcl-8.6.16" {
      script_config = {},
    } pkgs.system_image buildscript_tcl [tcl_src]
  in

  {
    include [
      tcl_src,
      buildscript_tcl,
      tcl,
    ],
  }
