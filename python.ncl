let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let python_src_3_13_7 =
    recipe.fetch "python-src-3.13.7" {
      url = [
        "https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tar.xz",
      ],
      hash = "md5:256cdb3bbf45cdce7499e52ba6c36ea3",
    }
  in

  let python_gen1_3_13_7 =
    recipe.binary "python-gen1-3.13.7" {
      kind = "binary-output",
      optimize = "size",
      script_config = {
        pre_configure = m%"
          cat > Modules/Setup.local <<'EOF_INNER'
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
          EOF_INNER
        "%,
        configure_args = [
          "--without-ensurepip",
        ],
        post_install = "ln -svf python3 \"/out/${out}/usr/bin/python\"",
      },
    } pkgs.host_image pkgs.buildscript_autotools [python_src_3_13_7]
  in

  {
    include [
      python_src_3_13_7,
      python_gen1_3_13_7,
    ],
  }
