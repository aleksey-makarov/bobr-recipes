fun pkgs =>
  let buildscript_base_filesystem =
    store.text "buildscript-base-filesystem" {
      kind = "build-script",
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
        dest="/out/${out}"

        mkdir -pv "$dest"/{etc,var,tmp,run,root,home}
        mkdir -pv "$dest"/usr/{bin,lib,sbin,share,include,libexec}
        mkdir -pv "$dest"/var/{log,mail,spool,tmp}

        ln -sv usr/bin  "$dest"/bin
        ln -sv usr/sbin "$dest"/sbin
        ln -sv usr/lib  "$dest"/lib
        case "$(uname -m)" in
          x86_64) ln -sv usr/lib "$dest"/lib64 ;;
        esac

        cat > "$dest"/etc/passwd <<'EOF'
        root:x:0:0:root:/root:/bin/bash
        nobody:x:65534:65534:nobody:/nonexistent:/usr/bin/false
        EOF

        cat > "$dest"/etc/group <<'EOF'
        root:x:0:
        bin:x:1:
        sys:x:2:
        kmem:x:9:
        wheel:x:10:
        nobody:x:65534:
        EOF

        cat > "$dest"/etc/ld.so.conf <<'EOF'
        /usr/lib
        EOF

        ln -sv /proc/self/mounts "$dest"/etc/mtab
        "%,
    }
  in

  let base_filesystem =
    store.bind buildscript_base_filesystem (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "base-filesystem" {
      kind = "binary-output",
      optimize = "size",
    } image script []))
  in

  {
    include [
      buildscript_base_filesystem,
      base_filesystem,
    ],
  }
