# flit_core -- the PEP 517 build backend at the base of the Python packaging
# stack. It bootstraps from its own source (pyproject backend-path = ["."]), so
# it needs no other backend. Build-only module.
fun pkgs =>
  let python_flit_core_src = {
    version | default = "3.12.0",
    name = "python-flit-core-src-%{version}",
    tag = "Source",
    object_hash | default = "18f63100d6f94385c6ed57a72073443e1a71a4acb4339491615d0f16d6ff01b2",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/f/flit-core/flit_core-%{version}.tar.gz",
    },
  }
  in

  let python_flit_core = {
    name = "python-flit-core-%{inputs.source.version}",
    tag = "PythonModule",
    deps = {
      build = [],
      runtime = [
        pkgs.python,
      ],
    },
    config = {},
    inputs = {
      source = pkgs.python_flit_core_src,
    },
  }
  in

  { include [python_flit_core_src, python_flit_core] }
