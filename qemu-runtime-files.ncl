let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let buildscript_qemu_runtime_files =
    recipe.text "buildscript-qemu-runtime-files" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
        dest="/out/${out}"

        mkdir -pv "$dest"/{dev,proc,sys}
        mkdir -pv "$dest"/etc

        cat > "$dest"/init <<'EOF_INNER'
        #!/bin/bash
        set -euo pipefail

        export PATH=/usr/bin:/usr/sbin:/bin:/sbin
        export HOME=/root
        export USER=root
        export SHELL=/bin/bash
        cd /root

        echo "mbuild qemu rootfs booted"
        exec /bin/bash -l
        EOF_INNER
        chmod 0755 "$dest"/init

        cat > "$dest"/etc/hostname <<'EOF_INNER'
        mbuild-qemu
        EOF_INNER

        cat > "$dest"/etc/issue <<'EOF_INNER'
        mbuild qemu rootfs
        EOF_INNER
        "%,
    }
  in

  let qemu_runtime_files =
    recipe.binary "qemu-runtime-files" {
    } pkgs.host_image buildscript_qemu_runtime_files []
  in

  {
    include [
      qemu_runtime_files,
    ],
  }
