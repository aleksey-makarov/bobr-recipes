let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let buildscript_base_filesystem =
    recipe.text "buildscript-base-filesystem" {
      kind = "build-script",
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"
        dest="/out/${out}"

        mkdir -pv "$dest"/{etc,var,tmp,run,root,home}
        mkdir -pv "$dest"/usr/{bin,lib,lib64,sbin,share,include,libexec}
        mkdir -pv "$dest"/var/{log,mail,spool,tmp}

        ln -sv usr/bin  "$dest"/bin
        ln -sv usr/sbin "$dest"/sbin
        ln -sv usr/lib  "$dest"/lib
        case "$(uname -m)" in
          x86_64) ln -sv usr/lib64 "$dest"/lib64 ;;
        esac

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

  let base_filesystem =
    recipe.binary "base-filesystem" {
      kind = "binary-output",
    } pkgs.host_image buildscript_base_filesystem []
  in

  {
    include [
      base_filesystem,
    ],
  }
