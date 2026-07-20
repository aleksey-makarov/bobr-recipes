let recipe = import "../recipe-lib.ncl" in
let br = import "../build-rootfs.ncl" in

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

  # `out_dir` is the install root: "@{out}" for the staging gen1 (MakefileRootfs),
  # "/stage" for the additive full bzip2 (MakefileStageRootfs, re-rooted by
  # TreeMove). bzip2's Makefile installs via PREFIX (not DESTDIR), so it needs a
  # custom install hook rather than the synthetic DESTDIR install.
  let bzip2_config = fun version => fun out_dir => {
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
          make PREFIX="%{out_dir}/usr" install
          mkdir -p "%{out_dir}/usr/lib" "%{out_dir}/usr/bin" "%{out_dir}/usr/include"
          cp -av libbz2.so.* "%{out_dir}/usr/lib/"
          ln -svf libbz2.so.%{version} "%{out_dir}/usr/lib/libbz2.so"
          cp -v bzip2-shared "%{out_dir}/usr/bin/bzip2"
          cp -v bzlib.h "%{out_dir}/usr/include/"
          for i in "%{out_dir}/usr/bin"/{bzcat,bunzip2,lbzip2}; do
            ln -sfv bzip2 "$i"
          done
          ln -sfv bzdiff "%{out_dir}/usr/bin/bzcmp"
          ln -sfv bzgrep "%{out_dir}/usr/bin/bzegrep"
          ln -sfv bzgrep "%{out_dir}/usr/bin/bzfgrep"
          ln -sfv bzmore "%{out_dir}/usr/bin/bzless"
          rm -fv "%{out_dir}/usr/lib/libbz2.a"
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
    # gen1 bootstraps in system_rootfs_1, before the self-hosted toolchain exists.
    config = bzip2_config version "@{out}",
    inputs = {
      _rootfs = pkgs.system_rootfs_1,
      source = bzip2_src version source_object_hash,
      install_docs_patch = bzip2_install_docs_patch,
    },
  }
  in

  # bzip2's build environment: the native toolchain WITHOUT bzip2. bzip2 is part
  # of the default toolchain (it unpacks others' .tar.bz2), so a deps-derived
  # rootfs would contain bzip2 -- a build cycle. Its own source is .tar.gz, so
  # its build needs no bzip2; list the deps explicitly here (also no xz, which it
  # does not need) rather than deriving from the default set. This replaces the
  # curated system_rootfs_2.
  #
  # Use the GEN1 kernel headers, not the plain ones: plain linux_headers builds
  # in native_toolchain_deps, which contains bzip2, so pulling it here would be a
  # bzip2 <-> linux_headers build cycle. gen1 builds in the external buildpack
  # rootfs (no bzip2) and its header content is identical.
  let bzip2_build_deps = [
    pkgs.linux_headers_gen1,
    pkgs.glibc,
    pkgs.binutils,
    pkgs.gcc,
    pkgs.bash,
    pkgs.make,
    pkgs.coreutils,
    pkgs.gawk,
    pkgs.sed,
    pkgs.grep,
    pkgs.tar,
    pkgs.gzip,
    pkgs.patch,
    pkgs.findutils,
    pkgs.diffutils,
  ]
  in

  let bzip2 = {
    version | default = "1.0.8",
    source_object_hash | default = "ab5a03176ee106d3f0fa90e381da478ddae405918153cca248e682cd0c4a2269",
    name = "bzip2-%{version}",
    tag = "MakefileStageRootfs",
    deps = {
      build = [],
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = bzip2_config version "/stage",
    inputs = {
      _rootfs =
        br.build_rootfs_closure pkgs "bzip2-%{version}-build-rootfs" bzip2_build_deps,
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
