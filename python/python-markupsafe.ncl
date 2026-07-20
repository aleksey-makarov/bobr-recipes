# MarkupSafe -- string escaping used by Jinja2 and Mako. Ships an optional C
# speedup that builds against the interpreter headers (present via the python
# build dep). setuptools backend. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_markupsafe_src = fun version => fun hash => {
    name = "python-markupsafe-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/M/MarkupSafe/markupsafe-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "3.0.2",
    source_object_hash | default = "ee55d3edf80167e48ea11a923c7386f4669df67d7994554387f84e7d8b0a2bf0",
    name = "python-markupsafe-%{version}",
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
      source = python_markupsafe_src version source_object_hash,
    },
  }
