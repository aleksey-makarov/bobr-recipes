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
    tag = "SandboxBuild",
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
              # relocatable toolchain into /usr.
              mkdir -p "@{out}/usr"
              cp -a "@{build}/source/." "@{out}/usr/"
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
