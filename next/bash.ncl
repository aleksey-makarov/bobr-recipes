{
  "bash-src-5.3" = {
    type = "fetch",
    outputs = ["bash-src-5.3"],
    url = [
      "https://ftp.gnu.org/gnu/bash/bash-5.3.tar.gz",
      "https://mirrors.kernel.org/gnu/bash/bash-5.3.tar.gz",
    ],
    hash = "md5:977c8c0c5ae6309191e7768e28ebc951",
  },

  "buildscript-bash-temp-5.3" = {
    type = "text",
    artifact_kind = "build-script",
    outputs = ["buildscript-bash-temp-5.3"],
    source = m%"
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

      export PATH="/tools/bin:${PATH:-}"

      ./configure --prefix=/usr                        \
                  --build="$(sh support/config.guess)" \
                  --host=x86_64-lfs-linux-gnu         \
                  --without-bash-malloc

      jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
      make -j"${jobs}"
      make DESTDIR="/out/${out}" install
      mkdir -p "/out/${out}/bin"
      ln -svf ../usr/bin/bash "/out/${out}/bin/sh"
      "%,
  },

  "bash-temp-5.3" = {
    type = "binary",
    inputs = [
      "bash-src-5.3",
      "buildscript-bash-temp-5.3",
      "bootstrap-for-stage1-userland",
    ],
    outputs = ["bash-temp-5.3"],
  },

  "buildscript-bash-stage2-5.3" = {
    type = "text",
    artifact_kind = "build-script",
    outputs = ["buildscript-bash-stage2-5.3"],
    source = m%"
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

      ./configure --prefix=/usr                        \
                  --build="$(sh support/config.guess)" \
                  --without-bash-malloc

      jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
      make -j"${jobs}"
      make DESTDIR="/out/${out}" install
      mkdir -p "/out/${out}/bin"
      ln -svf ../usr/bin/bash "/out/${out}/bin/sh"
      "%,
  },

  "bash-stage2-5.3" = {
    type = "binary",
    inputs = [
      "bash-src-5.3",
      "buildscript-bash-stage2-5.3",
      "bootstrap-image",
    ],
    outputs = ["bash-stage2-5.3"],
  },
}
