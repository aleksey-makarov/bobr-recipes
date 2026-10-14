# Jinja2 -- templating engine; systemd's build uses it to render unit/config
# templates. flit_core backend, MarkupSafe at runtime. Build-only module.
fun pkgs =>
  let python_jinja2_src = {
    version | default = "3.1.6",
    name = "python-jinja2-src-%{version}",
    tag = "Source",
    object_hash | default = "0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/J/Jinja2/jinja2-%{version}.tar.gz",
    },
  }
  in

  let python_jinja2 = {
    name = "python-jinja2-%{inputs.source.version}",
    tag = "PythonModule",
    deps = {
      build = [
        pkgs.python_flit_core,
      ],
      runtime = [
        pkgs.python,
        pkgs.python_markupsafe,
      ],
    },
    config = {},
    inputs = {
      source = pkgs.python_jinja2_src,
    },
  }
  in

  { include [python_jinja2_src, python_jinja2] }
