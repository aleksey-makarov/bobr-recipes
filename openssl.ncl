let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let openssl_src =
    recipe.fetch "openssl-src-3.5.2" {
      url = "https://github.com/openssl/openssl/releases/download/openssl-3.5.2/openssl-3.5.2.tar.gz",
      hash = "md5:890fc59f86fc21b5e4d1c031a698dbde",
    }
  in

  let buildscript_openssl =
    recipe.text "buildscript-openssl" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        cd "${MBUILD_SOURCE_DIR}"
        mkdir -p .tmp "${MBUILD_INSTALL_DIR}"
        export TMPDIR="${TMPDIR:-$PWD/.tmp}"

        ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"$jobs"

        sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
        make DESTDIR="${MBUILD_INSTALL_DIR}" MANSUFFIX=ssl install

        if [ -d "${MBUILD_INSTALL_DIR}/usr/share/doc/openssl" ]; then
          mv -v "${MBUILD_INSTALL_DIR}/usr/share/doc/openssl" "${MBUILD_INSTALL_DIR}/usr/share/doc/openssl-3.5.2"
        else
          install -vdm755 "${MBUILD_INSTALL_DIR}/usr/share/doc/openssl-3.5.2"
        fi

        cp -vfr doc/* "${MBUILD_INSTALL_DIR}/usr/share/doc/openssl-3.5.2"
      "%,
    }
  in

  let openssl =
    recipe.binary "openssl-3.5.2" {
      steps = [
        recipe.steps.step "install" "root" "${build_dir}" ["${script}"],
      ],
      script_config = {},
    } pkgs.system_image buildscript_openssl [openssl_src]
  in

  {
    include [
      openssl_src,
      buildscript_openssl,
      openssl,
    ],
  }
