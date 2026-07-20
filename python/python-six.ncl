# six -- Python 2/3 compatibility shim, still pulled in transitively by parts of
# the build toolchain. setuptools backend. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_six_src = fun version => fun hash => {
    name = "python-six-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/s/six/six-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "1.17.0",
    source_object_hash | default = "ff70335d468e7eb6ec65b95b99d3a2836546063f63acc5171de367e834932a81",
    name = "python-six-%{version}",
    tag = "PythonModule",
    deps = {
      build = [
        pkgs.python_setuptools,
      ],
      runtime = [
        pkgs.python,
      ],
    },
    config = {},
    inputs = {
      source = python_six_src version source_object_hash,
    },
  }
