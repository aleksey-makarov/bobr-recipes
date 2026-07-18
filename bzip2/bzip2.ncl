let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let bzip2_src = fun version => fun hash => {
    name = "bzip2-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://www.sourceware.org/pub/bzip2/bzip2-%{version}.tar.gz",
    },
  }
  in

  let bzip2_install_docs_patch = {
    name = "bzip2-install-docs-patch-1.0.8",
    tag = "Source",
    object_hash = import "bzip2-1.0.8-install_docs-1.patch.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "bzip2/bzip2-1.0.8-install_docs-1.patch",
    },
  }
  in

  let bzip2_config = fun version => {
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
          ln -svf libbz2.so.%{version} "@{out}/usr/lib/libbz2.so"
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
    version | default = "1.0.8",
    source_object_hash | default = "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269",
    name = "bzip2-gen1-%{version}",
    tag = "MakefileRootfs",
    config = bzip2_config version,
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = bzip2_src version source_object_hash,
      install_docs_patch = bzip2_install_docs_patch,
    },
  }
  in

  let bzip2 = {
    version | default = "1.0.8",
    source_object_hash | default = "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269",
    name = "bzip2-%{version}",
    tag = "MakefileRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = bzip2_config version,
    inputs = {
      _rootfs = pkgs.system_rootfs_2,
      source = bzip2_src version source_object_hash,
      install_docs_patch = bzip2_install_docs_patch,
    },
  }
  in

  {
    include [
      bzip2_gen1,
      bzip2,
    ],
  }
