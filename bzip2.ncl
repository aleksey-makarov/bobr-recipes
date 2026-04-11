let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let build = (import "build-lib.ncl") pkgs in

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
    build.build_make {
      name = "bzip2-1.0.8",
      sources = [bzip2_src, bzip2_install_docs_patch],
      script_config = {
        pre_build = m%"
          patch -Np1 -i /in/sources1
          sed -i 's@\\(ln -s -f \\)$(PREFIX)/bin/@\\1@' Makefile
          sed -i 's@(PREFIX)/man@(PREFIX)/share/man@g' Makefile
          make -f Makefile-libbz2_so
          make clean
        "%,
        install_args = [
          "PREFIX=/usr",
          "install",
        ],
        post_install = m%"
          mkdir -p "/out/${out}/usr/lib" "/out/${out}/usr/bin"
          cp -av libbz2.so.* "/out/${out}/usr/lib/"
          ln -svf libbz2.so.1.0.8 "/out/${out}/usr/lib/libbz2.so"
          cp -v bzip2-shared "/out/${out}/usr/bin/bzip2"
          for i in "/out/${out}/usr/bin"/{bzcat,bunzip2}; do
            ln -sfv bzip2 "$i"
          done
          rm -fv "/out/${out}/usr/lib/libbz2.a"
        "%,
      },
    }
  in

  {
    include [
      bzip2_src,
      bzip2,
    ],
  }
