fun pkgs =>
  let python_src_3_13_7 =
    store.fetch "python-src-3.13.7" {
      url = [
        "https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz",
      ],
      hash = "md5:256cdb3bbf45cdce7499e52ba6c36ea3",
    }
  in

  let buildscript_python_gen1_3_13_7 =
    store.text "buildscript-python-gen1-3.13.7" {
      kind = "build-script",
      source = m%"
        #!/usr/bin/env bash
        set -euo pipefail

        src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
        out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

        cd "/in/${src}"

        if [ ! -x ./configure ]; then
          candidates=()
          for d in ./*; do
            if [ -d "$d" ] && [ -x "$d/configure" ]; then
              candidates+=("$d")
            fi
          done
          if [ "${#candidates[@]}" -eq 1 ]; then
            cd "${candidates[0]}"
          fi
        fi

        cat > Modules/Setup.local <<'EOF'
        # Minimal bootstrap Python: keep a self-contained interpreter and
        # disable optional extension modules that would otherwise auto-detect
        # host libraries and leak them into bootstrap-image.
        *disabled*
        _uuid
        _ssl
        _hashlib
        _lzma
        binascii
        zlib
        _gdbm
        _ctypes
        _sqlite3
        _bz2
        _curses_panel
        _dbm
        readline
        _curses
        EOF

        ./configure                     \
          --prefix=/usr                 \
          --without-ensurepip

        jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
        make -j"${jobs}"
        make DESTDIR="/out/${out}" install
        ln -svf python3 "/out/${out}/usr/bin/python"
        "%,
    }
  in

  let python_gen1_3_13_7 =
    store.bind python_src_3_13_7 (fun python_src =>
    store.bind buildscript_python_gen1_3_13_7 (fun script =>
    store.bind pkgs.host_image (fun image =>
    store.binary "python-gen1-3.13.7" {
      kind = "binary-output",
      optimize = "size",
    } image script [python_src])))
  in

  {
    include [
      python_src_3_13_7,
      buildscript_python_gen1_3_13_7,
      python_gen1_3_13_7,
    ],
  }
