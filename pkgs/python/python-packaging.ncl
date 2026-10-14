# packaging -- version/specifier/marker utilities used across the packaging
# ecosystem (meson imports it). flit_core backend. Build-only module.
fun pkgs =>
  let python_packaging_src = {
    version | default = "25.0",
    name = "python-packaging-src-%{version}",
    tag = "Source",
    object_hash | default = "d443872c98d677bf60f6a1f2f8c1cb748e8fe762d2bf9d3148b5599295b0fc4f",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/p/packaging/packaging-%{version}.tar.gz",
    },
  }
  in

  let python_packaging = {
    name = "python-packaging-%{inputs.source.version}",
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
      source = pkgs.python_packaging_src,
    },
  }
  in

  { include [python_packaging_src, python_packaging] }
