# setuptools -- the classic PEP 517 build backend. Self-hosting: it builds its
# own wheel from source (pyproject backend-path), so it needs no other backend.
# Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_setuptools_src = fun version => fun hash => {
    name = "python-setuptools-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/s/setuptools/setuptools-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "80.9.0",
    source_object_hash | default = "f36b47402ecde768dbfafc46e8e4207b4360c654f1f3bb84475f0a28628fb19c",
    name = "python-setuptools-%{version}",
    tag = "PythonModule",
    deps = {
      build = [],
      runtime = [
        pkgs.python,
      ],
    },
    config = {},
    inputs = {
      source = python_setuptools_src version source_object_hash,
    },
  }
