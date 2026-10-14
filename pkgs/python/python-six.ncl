# six -- Python 2/3 compatibility shim, still pulled in transitively by parts of
# the build toolchain. setuptools backend. Build-only module.
fun pkgs =>
  let python_six_src = {
    version | default = "1.17.0",
    name = "python-six-src-%{version}",
    tag = "Source",
    object_hash | default = "ff70335d468e7eb6ec65b95b99d3a2836546063f63acc5171de367e834932a81",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/s/six/six-%{version}.tar.gz",
    },
  }
  in

  let python_six = {
    name = "python-six-%{inputs.source.version}",
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
      source = pkgs.python_six_src,
    },
  }
  in

  { include [python_six_src, python_six] }
