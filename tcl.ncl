let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let tcl_src = {
    name = "tcl-src-8.6.16",
    tag = "Source",
    object_hash = "29af15338ae522c3da77be6961ad094dcb3c8436543b5327a58c2d0f6f3c70cc",
    origin = {
      type = "http",
      url = [
        "https://downloads.sourceforge.net/project/tcl/Tcl/8.6.16/tcl8.6.16-src.tar.gz",
        "https://sourceforge.net/projects/tcl/files/Tcl/8.6.16/tcl8.6.16-src.tar.gz/download",
      ],
    },
  }
  in

  let buildscript_tcl = {
    name = "buildscript-tcl",
    tag = "Text",
    config = {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src_root="${MBUILD_SOURCE_DIR}"

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

        mkdir -p "${MBUILD_INSTALL_DIR}"
        make INSTALL_ROOT="${MBUILD_INSTALL_DIR}" install
        chmod 644 "${MBUILD_INSTALL_DIR}/usr/lib/libtclstub8.6.a"
        chmod u+w "${MBUILD_INSTALL_DIR}/usr/lib/libtcl8.6.so"
        make INSTALL_ROOT="${MBUILD_INSTALL_DIR}" install-private-headers
        ln -sfv tclsh8.6 "${MBUILD_INSTALL_DIR}/usr/bin/tclsh"
        mv "${MBUILD_INSTALL_DIR}/usr/share/man/man3/Thread.3" "${MBUILD_INSTALL_DIR}/usr/share/man/man3/Tcl_Thread.3"
      "%,
    },
    inputs = {},
  }
  in

  let tcl = {
    name = "tcl-8.6.16",
    tag = "SandboxBuild",
    deps = {
      build = [
        pkgs.linux_headers,
        pkgs.glibc,
        pkgs.binutils,
        pkgs.gcc,
        pkgs.make,
        pkgs.coreutils,
        pkgs.gawk,
        pkgs.sed,
        pkgs.grep,
        pkgs.findutils,
        pkgs.diffutils,
      ],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_SOURCE_DIR = "@{build}/source",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      script = buildscript_tcl,
      source = tcl_src,
    },
  }
  in

  {
    include [
      tcl_src,
      buildscript_tcl,
      tcl,
    ],
  }
