# wheel -- the reference wheel-building tool / bdist_wheel backend. flit_core
# backend. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_wheel_src = fun version => fun hash => {
    name = "python-wheel-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/w/wheel/wheel-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "0.46.1",
    source_object_hash | default = "fd477efb5da0f7df1d3c76c73c14394002c844451bd63229d8570f376f5e6a38",
    name = "python-wheel-%{version}",
    tag = "PythonModule",
    deps = {
      build = [
        pkgs.python_flit_core,
      ],
      runtime = [
        pkgs.python,
      ],
    },
    config = {},
    inputs = {
      source = python_wheel_src version source_object_hash,
    },
  }
