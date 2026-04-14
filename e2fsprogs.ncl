let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let e2fsprogs_src =
    recipe.fetch "e2fsprogs-src-1.47.3" {
      url = "https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.gz",
      hash = "md5:113d7a7ee0710d2a670a44692a35fd2e",
    }
  in

  let e2fsprogs_build_image =
    recipe.image "e2fsprogs-build-image" {} pkgs.system_image [
      pkgs.util_linux,
      pkgs.texinfo,
    ]
  in

  let buildscript_e2fsprogs =
    recipe.text "buildscript-e2fsprogs" {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"
        mkdir -pv build
        cd build
        mkdir -p .tmp "/out/${out}/usr/share/info"
        export TMPDIR="${TMPDIR:-$PWD/.tmp}"

        ../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"$jobs"
        make DESTDIR="/out/${out}" install

        rm -fv "/out/${out}/usr/lib/libcom_err.a" \
               "/out/${out}/usr/lib/libe2p.a" \
               "/out/${out}/usr/lib/libext2fs.a" \
               "/out/${out}/usr/lib/libss.a"

        if [ -f "/out/${out}/usr/share/info/libext2fs.info.gz" ]; then
          gunzip -vf "/out/${out}/usr/share/info/libext2fs.info.gz"
          install-info --dir-file="/out/${out}/usr/share/info/dir" "/out/${out}/usr/share/info/libext2fs.info"
        fi

        makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
        install -v -m644 doc/com_err.info "/out/${out}/usr/share/info"
        install-info --dir-file="/out/${out}/usr/share/info/dir" "/out/${out}/usr/share/info/com_err.info"
        rm -f "/out/${out}/usr/share/info/dir"

        if [ -f "/out/${out}/etc/mke2fs.conf" ]; then
          sed 's/metadata_csum_seed,//' -i "/out/${out}/etc/mke2fs.conf"
        fi

        if [ -f /etc/cron.d/e2scrub_all ]; then
          install -v -Dm644 /etc/cron.d/e2scrub_all "/out/${out}/etc/cron.d/e2scrub_all"
          rm -f /etc/cron.d/e2scrub_all
        fi

        for unit in e2scrub@.service e2scrub_all.service e2scrub_all.timer e2scrub_fail@.service; do
          if [ -f "/usr/lib/systemd/system/${unit}" ]; then
            install -v -Dm644 "/usr/lib/systemd/system/${unit}" "/out/${out}/usr/lib/systemd/system/${unit}"
            rm -f "/usr/lib/systemd/system/${unit}"
          fi
        done
      "%,
    }
  in

  let e2fsprogs =
    recipe.binary "e2fsprogs-1.47.3" {
      script_config = {},
    } e2fsprogs_build_image buildscript_e2fsprogs [e2fsprogs_src]
  in

  {
    include [
      e2fsprogs_src,
      buildscript_e2fsprogs,
      e2fsprogs,
    ],
  }
