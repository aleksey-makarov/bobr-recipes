# flit_core -- the PEP 517 build backend at the base of the Python packaging
# stack. It bootstraps from its own source (pyproject backend-path = ["."]), so
# it needs no other backend. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_flit_core_src = fun version => fun hash => {
    name = "python-flit-core-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/f/flit-core/flit_core-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "3.12.0",
    source_object_hash | default = "18f63100d6f94385c6ed57a72073443e1a71a4acb4339491615d0f16d6ff01b2",
    name = "python-flit-core-%{version}",
    tag = "PythonModule",
    deps = {
      build = [],
      runtime = [
        pkgs.python,
      ],
    },
    config = {},
    inputs = {
      source = python_flit_core_src version source_object_hash,
    },
  }
