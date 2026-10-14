# PyYAML -- YAML parser. Built as pure Python (PYYAML_FORCE_LIBYAML=0): the build
# rootfs has neither Cython nor libyaml, so the optional libyaml C extension is
# skipped rather than failing. setuptools backend. Build-only module.
fun pkgs =>
  let python_pyyaml_src = {
    version | default = "6.0.3",
    name = "python-pyyaml-src-%{version}",
    tag = "Source",
    object_hash | default = "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/P/PyYAML/pyyaml-%{version}.tar.gz",
    },
  }
  in

  let python_pyyaml = {
    name = "python-pyyaml-%{inputs.source.version}",
    tag = "PythonModule",
    deps = {
      build = [
        pkgs.python_setuptools,
      ],
      runtime = [
        pkgs.python,
      ],
    },
    config = {
      env = {
        PYYAML_FORCE_LIBYAML = "0",
      },
    },
    inputs = {
      source = pkgs.python_pyyaml_src,
    },
  }
  in

  { include [python_pyyaml_src, python_pyyaml] }
