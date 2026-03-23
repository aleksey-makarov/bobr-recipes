fun pkgs =>
  let pkg_name = "linux" in
  let pkg_version = "6.18.10" in

  let source_name = "%{pkg_name}-src-%{pkg_version}" in
  let headers_script_name = "buildscript-linux-headers-%{pkg_version}" in
  let headers_name = "linux-headers-%{pkg_version}" in

  let linux_src_6_18_10 =
    store.fetch source_name {
      url = "https://www.kernel.org/pub/linux/kernel/v6.x/linux-6.18.10.tar.xz",
      hash = "md5:660e706a43f634b1fcd911f8839d2f61",
    }
  in

  let buildscript_linux_headers_6_18_10 =
    store.text headers_script_name {
      kind = "build-script",
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
    }
  in

  let linux_headers_6_18_10 =
    store.bind linux_src_6_18_10 (fun src =>
    store.bind buildscript_linux_headers_6_18_10 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary headers_name {
      kind = "binary-output",
      optimize = "size",
    } image script [src])))
  in

  {
    include [
      linux_src_6_18_10,
      buildscript_linux_headers_6_18_10,
      linux_headers_6_18_10,
    ],
  }
