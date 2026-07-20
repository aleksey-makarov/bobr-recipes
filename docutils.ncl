# docutils -- reStructuredText toolkit. We use it as an application (its rst2man
# generates man pages, e.g. for mutter), so it lives in the root as an ordinary
# recipe rather than under python/ with the library modules; it still builds via
# the PythonModule tag (flit_core backend). See python/README.txt.
# `version`/`source_object_hash` are node fields (overridable).
fun pkgs =>
  let docutils_src = fun version => fun hash => {
    name = "docutils-src-%{version}",
    tag = "Source",
    object_hash = hash,
    origin = {
      tag = "Http",
      url = "https://pypi.org/packages/source/d/docutils/docutils-%{version}.tar.gz",
    },
  }
  in

  let docutils = {
    version | default = "0.21.2",
    source_object_hash | default = "3a6b18732edf182daa3cd12775bbb338cf5691468f91eeeb109deff6ebfa986f",
    name = "docutils-%{version}",
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
      source = docutils_src version source_object_hash,
    },
  }
  in

  { include [ docutils ] }
