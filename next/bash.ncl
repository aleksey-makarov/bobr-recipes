fun pkgs =>
  let bash_src_5_3 =
    store.fetch "bash-src-5.3" {
      url = [
        "https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz",
        "https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz",
      ],
      hash = "md5:977c8c0c5ae6309191e7768e28ebc951",
    }
  in

  let bash_buildscript_source_5_3 = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"

        if [ ! -x ./configure ]; then
          candidates=()
          for d in ./*; do
            if [ -d "$d" ] && [ -x "$d/configure" ] && [ -x "$d/support/config.guess" ]; then
              candidates+=("$d")
            fi
          done
          if [ "${#candidates[@]}" -eq 1 ]; then
            cd "${candidates[0]}"
          fi
        fi

        ./configure --prefix=/usr        \
                    --without-bash-malloc \
                    --disable-readline

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"${jobs}"
        make DESTDIR="/out/${out}" install
        ln -svf bash "/out/${out}/usr/bin/sh"
        "%
  in

  let buildscript_bash_gen1_5_3 =
    store.text "buildscript-bash-gen1-5.3" {
      kind = "build-script",
      source = bash_buildscript_source_5_3,
    }
  in

  let bash_gen1_5_3 =
    store.bind bash_src_5_3 (fun bash_src =>
    store.bind buildscript_bash_gen1_5_3 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "bash-gen1-5.3" {
      kind = "binary-output",
      optimize = "size",
    } image script [bash_src])))
  in

  let buildscript_bash_5_3 =
    store.text "buildscript-bash-5.3" {
      kind = "build-script",
      source = bash_buildscript_source_5_3,
    }
  in

  let bash_5_3 =
    store.bind bash_src_5_3 (fun bash_src =>
    store.bind buildscript_bash_5_3 (fun script =>
    store.bind pkgs.build_image (fun image =>
    store.binary "bash-5.3" {
      kind = "binary-output",
      optimize = "size",
    } image script [bash_src])))
  in

  {
    include [
      bash_src_5_3,
      bash_gen1_5_3,
      bash_5_3,
    ],
  }
