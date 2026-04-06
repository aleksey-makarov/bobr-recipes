let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_qemu_base_filesystem =
    recipe.text "buildscript-qemu-base-filesystem" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
        dest="/out/${out}"

        mkdir -pv "$dest"/{etc,var,tmp,run,root,home}
        mkdir -pv "$dest"/lib64
        mkdir -pv "$dest"/usr/{bin,lib,lib64,sbin,share,include,libexec}
        mkdir -pv "$dest"/var/{log,mail,spool,tmp}

        ln -sv usr/bin  "$dest"/bin
        ln -sv usr/sbin "$dest"/sbin
        ln -sv usr/lib  "$dest"/lib

        cat > "$dest"/etc/passwd <<'EOF_INNER'
        root:x:0:0:root:/root:/bin/bash
        nobody:x:65534:65534:nobody:/nonexistent:/usr/bin/false
        EOF_INNER

        cat > "$dest"/etc/group <<'EOF_INNER'
        root:x:0:
        bin:x:1:
        sys:x:2:
        kmem:x:9:
        wheel:x:10:
        nobody:x:65534:
        EOF_INNER

        cat > "$dest"/etc/ld.so.conf <<'EOF_INNER'
        /usr/lib
        /usr/lib64
        EOF_INNER

        ln -sv /proc/self/mounts "$dest"/etc/mtab
        "%,
    }
  in

  let qemu_base_filesystem =
    recipe.binary "qemu-base-filesystem" {
    } pkgs.host_image buildscript_qemu_base_filesystem []
  in

  {
    include [
      qemu_base_filesystem,
    ],
  }
