# Jinja2 -- templating engine; systemd's build uses it to render unit/config
# templates. flit_core backend, MarkupSafe at runtime. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_jinja2_src = fun version => fun hash => {
    name = "python-jinja2-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/J/Jinja2/jinja2-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "3.1.6",
    source_object_hash | default = "0137fb05990d35f1275a587e9aee6d56da821fc83491a0fb838183be43f66d6d",
    name = "python-jinja2-%{version}",
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
      source = python_jinja2_src version source_object_hash,
    },
  }
