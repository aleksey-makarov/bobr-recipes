{
  "buildscript-ncurses-pass1-6.5-20250809" = {
    type = "text",
    artifact_kind = "build-script",
    outputs = ["buildscript-ncurses-pass1-6.5-20250809"],
    source = m%"
      #!/usr/bin/env bash
      set -euo pipefail

      src="${MBUILD_SOURCE_INPUT:?MBUILD_SOURCE_INPUT is required}"
      out="${MBUILD_PRIMARY_OUTPUT:?MBUILD_PRIMARY_OUTPUT is required}"

      cd "/in/${src}"

      if [ ! -x ./configure ]; then
        candidates=()
        for d in ./*; do
          if [ -d "$d" ] && [ -x "$d/config.guess" ] && [ -x "$d/configure" ]; then
            candidates+=("$d")
          fi
        done
        if [ "${#candidates[@]}" -eq 1 ]; then
          cd "${candidates[0]}"
        fi
      fi

      export PATH="/tools/bin:${PATH:-}"

      mkdir -p build
      pushd build
        ../configure --prefix=/tools AWK=gawk
        make -C include
        make -C progs tic
        install -Dm755 progs/tic "/out/${out}/tools/bin/tic"
      popd

      export PATH="/out/${out}/tools/bin:/tools/bin:${PATH:-}"

      ./configure --prefix=/usr                \
                  --host=x86_64-lfs-linux-gnu  \
                  --build="$(./config.guess)"  \
                  --mandir=/usr/share/man      \
                  --with-manpage-format=normal \
                  --with-shared                \
                  --without-normal             \
                  --with-cxx-shared            \
                  --without-debug              \
                  --without-ada                \
                  --disable-stripping          \
                  AWK=gawk

      jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)"
      make -j"${jobs}"
      make DESTDIR="/out/${out}" install
      ln -svf libncursesw.so "/out/${out}/usr/lib/libncurses.so"
      sed -e 's/^#if.*XOPEN.*$/#if 1/' -i "/out/${out}/usr/include/curses.h"
      "%,
  },

  "ncurses-pass1-6.5-20250809" = {
    type = "binary",
    inputs = [
      "ncurses-src-6.5-20250809",
      "buildscript-ncurses-pass1-6.5-20250809",
      "bootstrap-pass1",
    ],
    outputs = ["ncurses-pass1-6.5-20250809"],
  },
  "ncurses-src-6.5-20250809" = {
    type = "fetch",
    outputs = ["ncurses-src-6.5-20250809"],
    url = "https://invisible-mirror.net/archives/ncurses/current/ncurses-6.5-20250809.tgz",
    hash = "md5:679987405412f970561cc85e1e6428a2",
  },
}
