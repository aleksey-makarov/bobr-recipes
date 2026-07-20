# Meson -- the build system driving most of the desktop stack. It is a Python
# application (invokes ninja at run time), so it lives in the root as an ordinary
# recipe rather than under python/ with the library modules; it still builds via
# the PythonModule tag (setuptools backend). See python/README.txt.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let meson_src = fun version => fun hash => {
    name = "meson-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://github.com/mesonbuild/meson/releases/download/%{version}/meson-%{version}.tar.gz",
    },
  }
  in

  let meson = {
    version | default = "1.8.3",
    source_object_hash | default = "f118aa910fc0a137cc2dd0122232dbf82153d9a12fb5b0f5bb64896f6a157abf",
    name = "meson-%{version}",
    tag = "PythonModule",
    deps = {
      build = [
        pkgs.python_setuptools,
      ],
      runtime = [
        pkgs.python,
        pkgs.ninja,
      ],
    },
    config = {
      # pip installs meson's Python package but not its shell completions; drop
      # them in from the source tree (as the old bundled build did).
      post_install = {
        name = "install_shell_completions",
        run_as = "root",
        argv = [
          "/bin/sh",
          "-ec",
          m%"
            install -Dm644 "@{build}/source/data/shell-completions/bash/meson" \
              /usr/share/bash-completion/completions/meson
            install -Dm644 "@{build}/source/data/shell-completions/zsh/_meson" \
              /usr/share/zsh/site-functions/_meson
          "%,
        ],
      },
    },
    inputs = {
      source = meson_src version source_object_hash,
    },
  }
  in

  { include [ meson ] }
