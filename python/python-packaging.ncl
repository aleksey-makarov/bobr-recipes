# packaging -- version/specifier/marker utilities used across the packaging
# ecosystem (meson imports it). flit_core backend. Build-only module.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let python_packaging_src = fun version => fun hash => {
    name = "python-packaging-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/p/packaging/packaging-%{version}.tar.gz",
    },
  }
  in

  {
    version | default = "25.0",
    source_object_hash | default = "d443872c98d677bf60f6a1f2f8c1cb748e8fe762d2bf9d3148b5599295b0fc4f",
    name = "python-packaging-%{version}",
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
      source = python_packaging_src version source_object_hash,
    },
  }
