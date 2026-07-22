# ninja -- small build system that Meson drives. Not a Python package: it
# bootstraps from its own source with `python configure.py --bootstrap`, which
# compiles the ninja binary with the C++ toolchain. python is a build-only
# dependency (runs configure.py); the result links only glibc/libstdc++.
# `version`/`source_object_hash` are node fields (overridable).
let recipe = import "recipe-lib.ncl" in
let br = import "build-rootfs.ncl" in

fun pkgs =>
  let ninja_src = fun version => fun hash => {
    name = "ninja-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/ninja-build/ninja/archive/v%{version}/ninja-%{version}.tar.gz",
    },
  }
  in

  let ninja = {
    version | default = "1.13.1",
    source_object_hash | default = "f0055ad0369bf2e372955ba55128d000cfcc21777057806015b45e4accbebf23",
    name = "ninja-%{version}",
    tag = "SandboxInstallDeps",
    deps = {
      build = br.native_build_deps pkgs @ [ pkgs.python ],
      runtime = [
        pkgs.glibc_libs,
        pkgs.gcc_libs,
      ],
    },
    config = {
      steps = [
        recipe.prepare_source_step,
        {
          name = "bootstrap",
          run_as = "build-user",
          cwd = "@{build}/source",
          argv = ["python3", "configure.py", "--bootstrap", "--verbose"],
        },
        {
          name = "install",
          run_as = "root",
          cwd = "@{build}/source",
          argv = [
            "/bin/bash",
            "-ec",
            m%"
              install -vm755 ninja /usr/bin/ninja
              install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
              install -vDm644 misc/zsh-completion /usr/share/zsh/site-functions/_ninja
            "%,
          ],
        },
      ],
      script_config = {},
    },
    inputs = {
      source = ninja_src version source_object_hash,
    },
  }
  in

  { include [ ninja ] }
