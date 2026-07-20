# duktape -- a small, embeddable ECMAScript engine. polkit (linked by
# gnome-shell via polkit-agent-1) uses it as its rule-evaluation JS engine.
# Upstream ships only an amalgamated single-file source and a non-installing
# Makefile, so a small build driver (duktape-build.sh) compiles the shared
# library and lays out the install tree. Build rootfs is the native toolchain
# closure -- duktape needs nothing beyond a C compiler and libm.
# `version`/`source_object_hash` are node fields (overridable).
let recipe = import "../recipe-lib.ncl" in

fun pkgs =>
  let buildscript_duktape = {
    name = "buildscript-duktape",
    tag = "Source",
    object_hash = import "duktape-build.sh.fsobj-hash" as 'Text,
    origin = {
      tag = "RecipePath",
      path = "duktape/duktape-build.sh",
    },
  }
  in

  let duktape_src = fun version =>
    fun hash =>
      {
        name = "duktape-src-%{version}",
        tag = "Source",
        object_hash = hash,
        origin = {
          tag = "Http",
          url = "https://github.com/svaarala/duktape/releases/download/v%{version}/duktape-%{version}.tar.xz",
        },
      }
  in

  let step_env = { BOBR_SOURCE_DIR = "@{build}/source" } in

  let duktape = {
    version | default = "2.7.0",
    source_object_hash
      | default
      = "90f8d2fa8b5567c6899830ddef2c03f3c27960b11aca222fa17aa7ac613c2890",
    name = "duktape-%{version}",
    # Deps-derived additive SandboxInstallBuild: the builder assembles the build
    # rootfs from deps.build (the native toolchain -- cc + libm are all duktape
    # needs) instead of a hand-rolled _rootfs, and captures the install
    # additively into /. duktape's output (libduktape.so*, the two headers,
    # duktape.pc) does not overlap the toolchain rootfs, so it needs neither the
    # staging Sandbox model nor the /stage + TreeMove of a *StageRootfs.
    tag = "SandboxInstallBuild",
    deps = {
      build = recipe.native_build_deps pkgs,
      runtime = [
        pkgs.glibc_libs,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
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
      script = buildscript_duktape,
      source = duktape_src version source_object_hash,
    },
  }
  in

  {
    include [
      duktape,
    ],
  }
