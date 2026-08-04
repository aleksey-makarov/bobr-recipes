# Mako -- templating engine used by gobject-introspection's g-ir-scanner.
# setuptools backend, MarkupSafe at runtime. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_mako_src = fun version => fun hash => {
    name = "python-mako-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/M/Mako/mako-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "1.3.12",
    source_object_hash | default = "9f778e93289bd410bb35daadeb4fc66d95a746f0b75777b942088b7fd7af550a",
    name = "python-mako-%{version}",
    tag = "PythonModule",
    deps = {
      build = [
        pkgs.python_setuptools,
      ],
      runtime = [
        pkgs.python,
        pkgs.python_markupsafe,
      ],
    },
    config = {},
    inputs = {
      source = python_mako_src version source_object_hash,
    },
  }
