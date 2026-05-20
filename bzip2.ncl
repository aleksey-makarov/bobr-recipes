let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let bzip2_src = {
    name = "bzip2-src-1.0.8",
    tag = "Source",
    object_hash = "f382e89751370f5f2989ca9c0ad93a8cdf2309512b6d5387df7e57d81a6c7e13",
    origin = {
      type = "http",
      url = "https://www.sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz",
    },
  }
  in

  let bzip2_install_docs_patch = {
    name = "bzip2-install-docs-patch-1.0.8",
    tag = "Source",
    object_hash = "82d81e77925fc97f8b0c0ea887ce5c3d9cc42525ae926db16140c34d8a2bbfee",
    origin = {
      type = "http",
      url = "https://www.linuxfromscratch.org/patches/lfs/12.4/bzip2-1.0.8-install_docs-1.patch",
    },
  }
  in

  let bzip2_config = {
    pre_build = {
      name = "prepare_source",
      run_as = "build-user",
      argv = [
        "/bin/sh",
        "-ec",
        m%"
          patch -Np1 -i "@{install_docs_patch}"
          sed -i 's@\\(ln -s -f \\)$(PREFIX)/bin/@\\1@' Makefile
          sed -i 's@(PREFIX)/man@(PREFIX)/share/man@g' Makefile
          make -f Makefile-libbz2_so
          make clean
        "%,
      ],
    },
    skip_install = true,
    post_install = {
      name = "install_runtime",
      run_as = "root",
      cwd = "@{build}/source",
      argv = [
        "/bin/sh",
        "-ec",
        m%"
          make PREFIX="@{out}/usr" install
          mkdir -p "@{out}/usr/lib" "@{out}/usr/bin" "@{out}/usr/include"
          cp -av libbz2.so.* "@{out}/usr/lib/"
          ln -svf libbz2.so.1.0.8 "@{out}/usr/lib/libbz2.so"
          cp -v bzip2-shared "@{out}/usr/bin/bzip2"
          cp -v bzlib.h "@{out}/usr/include/"
          for i in "@{out}/usr/bin"/{bzcat,bunzip2,lbzip2}; do
            ln -sfv bzip2 "$i"
          done
          ln -sfv bzdiff "@{out}/usr/bin/bzcmp"
          ln -sfv bzgrep "@{out}/usr/bin/bzegrep"
          ln -sfv bzgrep "@{out}/usr/bin/bzfgrep"
          ln -sfv bzmore "@{out}/usr/bin/bzless"
          rm -fv "@{out}/usr/lib/libbz2.a"
        "%,
      ],
    },
  }
  in

  let bzip2_gen1 = {
    name = "bzip2-gen1-1.0.8",
    tag = "Makefile",
    config = bzip2_config,
    inputs = {
      rootfs = pkgs.system_rootfs_1,
      source = bzip2_src,
      install_docs_patch = bzip2_install_docs_patch,
    },
  }
  in

  let bzip2 = {
    name = "bzip2-1.0.8",
    tag = "Makefile",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = bzip2_config,
    inputs = {
      rootfs = pkgs.system_rootfs_2,
      source = bzip2_src,
      install_docs_patch = bzip2_install_docs_patch,
    },
  }
  in

  {
    include [
      bzip2_src,
      bzip2_gen1,
      bzip2,
    ],
  }
