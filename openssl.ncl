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

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"
        mkdir -p .tmp "/out/${out}"
        export TMPDIR="${TMPDIR:-$PWD/.tmp}"

        ./config --prefix=/usr --openssldir=/etc/ssl --libdir=lib shared zlib-dynamic

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"$jobs"

        sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
        make DESTDIR="/out/${out}" MANSUFFIX=ssl install

        if [ -d "/out/${out}/usr/share/doc/openssl" ]; then
          mv -v "/out/${out}/usr/share/doc/openssl" "/out/${out}/usr/share/doc/openssl-3.5.2"
        else
          install -vdm755 "/out/${out}/usr/share/doc/openssl-3.5.2"
        fi

        cp -vfr doc/* "/out/${out}/usr/share/doc/openssl-3.5.2"
      "%,
    }
  in

  let openssl =
    recipe.binary "openssl-3.5.2" {
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
