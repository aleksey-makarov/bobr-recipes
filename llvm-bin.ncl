# Prebuilt clang/LLVM toolchain, used as a BUILD tool only (mozjs/SpiderMonkey
# needs clang to compile and libclang for bindgen; building LLVM from source is a
# huge detour). Same rationale as rust-bin.ncl: the official release targets an
# old glibc (ubuntu-18.04), so it runs forward-compatibly on our newer glibc, and
# clang is relocatable, so installing the tree under /usr works. Never ships in a
# runtime rootfs -- only appears in build rootfs closures.
#
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.
let recipe = import "recipe-lib.ncl" in

fun pkgs =>
  let mk_src = fun version =>
    fun hash =>
      {
        name = "llvm-bin-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-%{version}/clang+llvm-%{version}-x86_64-linux-gnu-ubuntu-18.04.tar.xz",
        },
      }
  in

  let llvm_bin = {
    version | default = "18.1.8",
    source_object_hash
      | default
      = "54ec30358afcc9fb8aa74307db3046f5187f9fb89fb37064cdde906e062ebf36",
    name = "llvm-bin-%{version}",
    tag = "SandboxInstallDeps",
    deps = {
      build = [
        pkgs.coreutils,
        pkgs.findutils,
        pkgs.grep,
        pkgs.sed,
        pkgs.gawk,
        pkgs.tar,
      ],
      # Shared libs the clang/llvm binaries link at run time. Best-effort;
      # verify with `ldd bin/clang` once mozjs actually invokes it and add any
      # missing ones (e.g. libedit) rather than guessing further here.
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.zlib,
        pkgs.ncurses,
        pkgs.libxml2,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = [
            "/bin/sh",
            "-ec",
            m%"
              # The tarball unpacks to bin/ lib/ include/ libexec/ share/ under
              # @{build}/source (prepare_source strips the top dir); drop the whole
              # relocatable toolchain into /usr in the live overlay root (additive).
              #
              # cp -Rd --preserve=mode: keep symlinks and exec bits, but let the
              # new files be created as root:root (this step runs as root) -- do NOT
              # preserve the unpack (build-user) ownership, and do NOT chown -R
              # /usr afterwards (that would rewrite the ownership of the lower
              # toolchain's files too -> a non-additive copy-up, rejected by the
              # additive validator). Existing lower dirs (/usr/bin, /usr/lib, ...)
              # keep their metadata; only the new files/dirs are added.
              cp -Rd --preserve=mode "@{build}/source/." "/usr/"
              # The ubuntu-18.04 prebuilt clang links libtinfo.so.5 (a separate
              # terminfo lib in that era). Our ncurses is built
              # --with-termlib=tinfo, so a real libtinfo.so.6 exists; bridge the
              # soname to it (the terminfo ABI is stable across ncurses 5/6).
              # (ncurses is in this package's runtime deps.)
              ln -sf libtinfo.so.6 "/usr/lib/libtinfo.so.5"
            "%,
          ],
        },
      ],
      script_config = {},
    },
    inputs = {
      source = mk_src version source_object_hash,
    },
  }
  in

  {
    include [
      llvm_bin,
    ],
  }
