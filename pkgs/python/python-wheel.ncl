# wheel -- the reference wheel-building tool / bdist_wheel backend. flit_core
# backend. Build-only module.
fun pkgs =>
  let python_wheel_src = {
    version | default = "0.46.1",
    name = "python-wheel-src-%{version}",
    tag = "Source",
    object_hash | default = "fd477efb5da0f7df1d3c76c73c14394002c844451bd63229d8570f376f5e6a38",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/w/wheel/wheel-%{version}.tar.gz",
    },
  }
  in

  let python_wheel = {
    name = "python-wheel-%{inputs.source.version}",
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
      source = pkgs.python_wheel_src,
    },
  }
  in

  { include [python_wheel_src, python_wheel] }
