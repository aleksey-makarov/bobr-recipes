{
  "linux-src-6.18.10" = {
    type = "fetch",
    outputs = ["linux-src-6.18.10"],
    url = "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz",
    hash = "md5:660e706a43f634b1fcd911f8839d2f61",
  },

  "buildscript-linux-headers-temp-6.18.10" = {
    type = "text",
    artifact_kind = "build-script",
    outputs = ["buildscript-linux-headers-temp-6.18.10"],
    source = m%"
      #!/usr/bin/env bash
      set -euo pipefail

      src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
      out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

      cd "/in/${src}"

      if [ ! -f Makefile ]; then
        candidates=()
        for d in ./*; do
          if [ -d "$d" ] && [ -f "$d/Makefile" ]; then
            candidates+=("$d")
          fi
        done
        if [ "${#candidates[@]}" -eq 1 ]; then
          cd "${candidates[0]}"
        fi
      fi

      make mrproper
      make headers
      find usr/include -type f ! -name '*.h' -delete

      mkdir -p "/out/${out}/usr"
      cp -rv usr/include "/out/${out}/usr"
      "%,
  },

  "linux-headers-temp-6.18.10" = {
    type = "binary",
    inputs = [
      "linux-src-6.18.10",
      "buildscript-linux-headers-temp-6.18.10",
      "host-image",
    ],
    outputs = ["linux-headers-temp-6.18.10"],
  },
}
