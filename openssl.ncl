fun pkgs =>
  let openssl_src = {
    name = "openssl-src-3.5.2",
    tag = "Fetch",
    config = {
      url = "https://github.com/openssl/openssl/releases/download/openssl-3.5.2/openssl-3.5.2.tar.gz",
      hash = "md5:890fc59f86fc21b5e4d1c031a698dbde",
    },
    inputs = {},
  }
  in

  let buildscript_openssl = {
    name = "buildscript-openssl",
    tag = "Text",
    config = {
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
    },
    inputs = {},
  }
  in

  let openssl = {
    name = "openssl-3.5.2",
    tag = "Binary",
    config = {
      steps = [
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}"],
          env = {
            MBUILD_SOURCE_DIR = "@{source}",
            MBUILD_INSTALL_DIR = "@{out}",
          },
        },
      ],
      script_config = {},
    },
    inputs = {
      image = pkgs.system_image,
      script = buildscript_openssl,
      source = openssl_src,
    },
  }
  in

  {
    include [
      openssl_src,
      buildscript_openssl,
      openssl,
    ],
  }
