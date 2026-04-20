let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bzip2_src =
    {
      name = "bzip2-src-1.0.8",
      tag = "Fetch",
      config = {
      url = "https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz",
      hash = "md5:67e051268d0c475ea773822f7500d0e5",
      },
      inputs = {},
    }
  in

  let bzip2_install_docs_patch =
    {
      name = "bzip2-install-docs-patch-1.0.8",
      tag = "Fetch",
      config = {
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/bzip2-1.0.8-install_docs-1.patch",
      hash = "md5:6a5ac7e89b791aae556de0f745916f7f",
      unpack = false,
      },
      inputs = {},
    }
  in

  let bzip2 =
    recipe.binary "bzip2-1.0.8" {
      script_config = {
        pre_build = m%"
          patch -Np1 -i /in/sources1
          sed -i 's@\\(ln -s -f \\)$(PREFIX)/bin/@\\1@' Makefile
          sed -i 's@(PREFIX)/man@(PREFIX)/share/man@g' Makefile
          make -f Makefile-libbz2_so
          make clean
        "%,
        skip_install = "true",
        post_install = m%"
          make PREFIX="${MBUILD_INSTALL_DIR}/usr" install
          mkdir -p "${MBUILD_INSTALL_DIR}/usr/lib" "${MBUILD_INSTALL_DIR}/usr/bin" "${MBUILD_INSTALL_DIR}/usr/include"
          cp -av libbz2.so.* "${MBUILD_INSTALL_DIR}/usr/lib/"
          ln -svf libbz2.so.1.0.8 "${MBUILD_INSTALL_DIR}/usr/lib/libbz2.so"
          cp -v bzip2-shared "${MBUILD_INSTALL_DIR}/usr/bin/bzip2"
          cp -v bzlib.h "${MBUILD_INSTALL_DIR}/usr/include/"
          for i in "${MBUILD_INSTALL_DIR}/usr/bin"/{bzcat,bunzip2}; do
            ln -sfv bzip2 "$i"
          done
          ln -sfv bzdiff "${MBUILD_INSTALL_DIR}/usr/bin/bzcmp"
          ln -sfv bzgrep "${MBUILD_INSTALL_DIR}/usr/bin/bzegrep"
          ln -sfv bzgrep "${MBUILD_INSTALL_DIR}/usr/bin/bzfgrep"
          ln -sfv bzmore "${MBUILD_INSTALL_DIR}/usr/bin/bzless"
          rm -fv "${MBUILD_INSTALL_DIR}/usr/lib/libbz2.a"
        "%,
      },
    } pkgs.system_image_2 pkgs.buildscript_gnu_make [bzip2_src, bzip2_install_docs_patch]
  in

  {
    include [
      bzip2_src,
      bzip2,
    ],
  }
