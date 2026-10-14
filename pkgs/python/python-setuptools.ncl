# setuptools -- the classic PEP 517 build backend. Self-hosting: it builds its
# own wheel from source (pyproject backend-path), so it needs no other backend.
# Build-only module.
fun pkgs =>
  let python_setuptools_src = {
    version | default = "80.9.0",
    name = "python-setuptools-src-%{version}",
    tag = "Source",
    object_hash | default = "f36b47402ecde768dbfafc46e8e4207b4360c654f1f3bb84475f0a28628fb19c",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/s/setuptools/setuptools-%{version}.tar.gz",
    },
  }
  in

  let python_setuptools = {
    name = "python-setuptools-%{inputs.source.version}",
    tag = "PythonModule",
    deps = {
      build = [],
      runtime = [
        pkgs.python,
      ],
    },
    config = {},
    inputs = {
      source = pkgs.python_setuptools_src,
    },
  }
  in

  { include [python_setuptools_src, python_setuptools] }
