# MarkupSafe -- string escaping used by Jinja2 and Mako. Ships an optional C
# speedup that builds against the interpreter headers (present via the python
# build dep). setuptools backend. Build-only module.
fun pkgs =>
  let python_markupsafe_src = {
    version | default = "3.0.2",
    name = "python-markupsafe-src-%{version}",
    tag = "Source",
    object_hash | default = "ee55d3edf80167e48ea11a923c7386f4669df67d7994554387f84e7d8b0a2bf0",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/M/MarkupSafe/markupsafe-%{version}.tar.gz",
    },
  }
  in

  let python_markupsafe = {
    name = "python-markupsafe-%{inputs.source.version}",
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
      source = pkgs.python_markupsafe_src,
    },
  }
  in

  { include [python_markupsafe_src, python_markupsafe] }
