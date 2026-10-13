# docutils -- reStructuredText toolkit. We use it as an application (its rst2man
# generates man pages, e.g. for mutter), so it lives in the root as an ordinary
# recipe rather than under python/ with the library modules; it still builds via
# the PythonModule tag (flit_core backend). See python/README.txt.
# Configure version and hash through `pkgs.docutils_src`.
fun pkgs =>
  let docutils_src = {
    version | default = "0.21.2",
    name = "docutils-src-%{version}",
    tag = "Source",
    object_hash | default = "3a6b18732edf182daa3cd12775bbb338cf5691468f91eeeb109deff6ebfa986f",
    origin = {
      tag = "Http",
      url = "https://files.pythonhosted.org/packages/source/d/docutils/docutils-%{version}.tar.gz",
    },
  }
  in

  let docutils = {
    name = "docutils-%{inputs.source.version}",
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
      source = pkgs.docutils_src,
    },
  }
  in

  {
    include [
      docutils_src,
      docutils
    ]
  }
