let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let e2fsprogs_src = {
    name = "e2fsprogs-src-1.47.3",
    tag = "Fetch",
    config = {
      url = "https://downloads.sourceforge.net/project/e2fsprogs/e2fsprogs/v1.47.3/e2fsprogs-1.47.3.tar.gz",
      hash = "md5:113d7a7ee0710d2a670a44692a35fd2e",
    },
    inputs = {},
  }
  in

  let e2fsprogs_build_image = {
    name = "e2fsprogs-build-image",
    tag = "Image",
    config = { ref_name | default = "e2fsprogs-build-image" } & {},
    inputs = {
      base = pkgs.system_image,
      inputs = [
        pkgs.util_linux,
        pkgs.texinfo,
      ],
    },
  }
  in

  let buildscript_e2fsprogs = {
    name = "buildscript-e2fsprogs",
    tag = "Text",
    config = {
      executable = true,
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        cd "${MBUILD_SOURCE_DIR}"
        mkdir -pv build
        cd build
        mkdir -p .tmp "${MBUILD_INSTALL_DIR}/usr/share/info"
        export TMPDIR="${TMPDIR:-$PWD/.tmp}"

        ../configure --prefix=/usr --sysconfdir=/etc --enable-elf-shlibs --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"$jobs"
        make DESTDIR="${MBUILD_INSTALL_DIR}" install

        rm -fv "${MBUILD_INSTALL_DIR}/usr/lib/libcom_err.a" \
               "${MBUILD_INSTALL_DIR}/usr/lib/libe2p.a" \
               "${MBUILD_INSTALL_DIR}/usr/lib/libext2fs.a" \
               "${MBUILD_INSTALL_DIR}/usr/lib/libss.a"

        if [ -f "${MBUILD_INSTALL_DIR}/usr/share/info/libext2fs.info.gz" ]; then
          gunzip -vf "${MBUILD_INSTALL_DIR}/usr/share/info/libext2fs.info.gz"
          install-info --dir-file="${MBUILD_INSTALL_DIR}/usr/share/info/dir" "${MBUILD_INSTALL_DIR}/usr/share/info/libext2fs.info"
        fi

        makeinfo -o doc/com_err.info ../lib/et/com_err.texinfo
        install -v -m644 doc/com_err.info "${MBUILD_INSTALL_DIR}/usr/share/info"
        install-info --dir-file="${MBUILD_INSTALL_DIR}/usr/share/info/dir" "${MBUILD_INSTALL_DIR}/usr/share/info/com_err.info"
        rm -f "${MBUILD_INSTALL_DIR}/usr/share/info/dir"

        if [ -f "${MBUILD_INSTALL_DIR}/etc/mke2fs.conf" ]; then
          sed 's/metadata_csum_seed,//' -i "${MBUILD_INSTALL_DIR}/etc/mke2fs.conf"
        fi

        if [ -f /etc/cron.d/e2scrub_all ]; then
          install -v -Dm644 /etc/cron.d/e2scrub_all "${MBUILD_INSTALL_DIR}/etc/cron.d/e2scrub_all"
          rm -f /etc/cron.d/e2scrub_all
        fi

        for unit in e2scrub@.service e2scrub_all.service e2scrub_all.timer e2scrub_fail@.service; do
          if [ -f "/usr/lib/systemd/system/${unit}" ]; then
            install -v -Dm644 "/usr/lib/systemd/system/${unit}" "${MBUILD_INSTALL_DIR}/usr/lib/systemd/system/${unit}"
            rm -f "/usr/lib/systemd/system/${unit}"
          fi
        done
      "%,
    },
    inputs = {},
  }
  in

  let e2fsprogs =
    recipe.binary
      "e2fsprogs-1.47.3"
      {
        steps = [
          recipe.steps.step "install" "root" "${build_dir}" ["${script}"],
        ],
        script_config = {},
      }
      e2fsprogs_build_image
      buildscript_e2fsprogs
      [e2fsprogs_src]
  in

  {
    include [
      e2fsprogs_src,
      buildscript_e2fsprogs,
      e2fsprogs,
    ],
  }
