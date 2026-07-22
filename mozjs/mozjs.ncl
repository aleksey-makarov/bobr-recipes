# mozjs / SpiderMonkey -- the JavaScript engine gjs (and thus gnome-shell) embed.
# Built from the full firefox-esr source (only the JS engine) via the standalone
# js/src/configure in an objdir; see mozjs-configure.sh. Uses our prebuilt clang
# (libclang for bindgen), rust (+rustfmt), cbindgen, nasm, and system ICU/zlib.
# The build rootfs is assembled as a closure (base_filesystem + native toolchain
# + these tools) -- no system_rootfs_X.
#
# `version`/`source_object_hash` are node fields (overridable), as in linux.ncl.
let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_mozjs = {
    name = "buildscript-mozjs-configure",
    tag = "Source",
    object_hash = import "mozjs-configure.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "mozjs/mozjs-configure.sh",
    },
  }
  in

  let mozjs_src = fun version =>
    fun hash =>
      {
        name = "mozjs-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://archive.mozilla.org/pub/firefox/releases/%{version}/source/firefox-%{version}.source.tar.xz",
        },
      }
  in

  let step_env = { BOBR_SOURCE_DIR = "@{build}/source" } in

  let mozjs = {
    version | default = "140.12.0esr",
    source_object_hash
      | default
      = "85dfb9f6021152b4302b8968ef485d958c8c471cb02415a19853daaad5acce62",
    name = "mozjs-%{version}",
    tag = "SandboxStageDeps",
    deps = {
      # Deps-derived build rootfs (SandboxStageDeps assembles it, no hand-rolled
      # _rootfs): the native toolchain plus our prebuilt clang (libclang for
      # bindgen), rust (+rustfmt), cbindgen, nasm, python, pkgconf and system
      # ICU/zlib -- replacing system_rootfs_X.
      build =
        recipe.native_build_deps pkgs
        @ [
          pkgs.llvm_bin,
          pkgs.rust_bin,
          pkgs.cbindgen,
          pkgs.nasm,
          pkgs.python,
          pkgs.pkgconf,
          pkgs.icu,
          pkgs.zlib,
        ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
        pkgs.icu,
        pkgs.zlib,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "configure",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "configure"],
          env = step_env,
        },
        {
          name = "build",
          run_as = "build-user",
          cwd = "@{build}",
          argv = ["@{script}", "build"],
          env = step_env,
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}",
          argv = ["@{script}", "install"],
          env = step_env,
        },
      ],
    },
    inputs = {
      script = buildscript_mozjs,
      source = mozjs_src version source_object_hash,
    },
  }
  in

  {
    include [
      mozjs,
    ],
  }
