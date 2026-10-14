# Mako -- templating engine used by gobject-introspection's g-ir-scanner.
# setuptools backend, MarkupSafe at runtime. Build-only module.
fun pkgs =>
  let python_mako_src = {
    version | default = "1.3.12",
    name = "python-mako-src-%{version}",
    tag = "Source",
    object_hash | default = "9f778e93289bd410bb35daadeb4fc66d95a746f0b75777b942088b7fd7af550a",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/M/Mako/mako-%{version}.tar.gz",
    },
  }
  in

  let python_mako = {
    name = "python-mako-%{inputs.source.version}",
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
      source = pkgs.python_mako_src,
    },
  }
  in

  { include [python_mako_src, python_mako] }
