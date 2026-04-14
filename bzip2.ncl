let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bzip2_src =
    recipe.fetch "bzip2-src-1.0.8" {
      url = "https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz",
      hash = "md5:67e051268d0c475ea773822f7500d0e5",
    }
  in

  let bzip2_install_docs_patch =
    recipe.fetch "bzip2-install-docs-patch-1.0.8" {
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/bzip2-1.0.8-install_docs-1.patch",
      hash = "md5:6a5ac7e89b791aae556de0f745916f7f",
      unpack = false,
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
          make PREFIX="/out/${out}/usr" install
          mkdir -p "/out/${out}/usr/lib" "/out/${out}/usr/bin" "/out/${out}/usr/include"
          cp -av libbz2.so.* "/out/${out}/usr/lib/"
          ln -svf libbz2.so.1.0.8 "/out/${out}/usr/lib/libbz2.so"
          cp -v bzip2-shared "/out/${out}/usr/bin/bzip2"
          cp -v bzlib.h "/out/${out}/usr/include/"
          for i in "/out/${out}/usr/bin"/{bzcat,bunzip2}; do
            ln -sfv bzip2 "$i"
          done
          ln -sfv bzdiff "/out/${out}/usr/bin/bzcmp"
          ln -sfv bzgrep "/out/${out}/usr/bin/bzegrep"
          ln -sfv bzgrep "/out/${out}/usr/bin/bzfgrep"
          ln -sfv bzmore "/out/${out}/usr/bin/bzless"
          rm -fv "/out/${out}/usr/lib/libbz2.a"
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
