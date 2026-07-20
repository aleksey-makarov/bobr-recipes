# PyYAML -- YAML parser. Built as pure Python (PYYAML_FORCE_LIBYAML=0): the build
# rootfs has neither Cython nor libyaml, so the optional libyaml C extension is
# skipped rather than failing. setuptools backend. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_pyyaml_src = fun version => fun hash => {
    name = "python-pyyaml-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/P/PyYAML/pyyaml-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "6.0.3",
    source_object_hash | default = "d76623373421df22fb4cf8817020cbb7ef15c725b9d5e45f17e189bfc384190f",
    name = "python-pyyaml-%{version}",
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
      source = python_pyyaml_src version source_object_hash,
    },
  }
